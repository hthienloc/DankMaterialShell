package screenshot

import (
	"encoding/json"
	"image"
	"image/color"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"
	"sync"

	"golang.org/x/image/font"
	"golang.org/x/image/font/opentype"
	"golang.org/x/image/math/fixed"
)

var (
	hudFontOnce sync.Once
	hudFont     *opentype.Font

	hudFaceMu  sync.Mutex
	hudFaces   = map[int]font.Face{}
	hudFaceErr error
)

func hudMonoFamily() string {
	if configDir, err := os.UserConfigDir(); err == nil {
		data, err := os.ReadFile(filepath.Join(configDir, "DankMaterialShell", "settings.json"))
		if err == nil {
			var s struct {
				MonoFontFamily string `json:"monoFontFamily"`
			}
			if json.Unmarshal(data, &s) == nil {
				if f := strings.TrimSpace(s.MonoFontFamily); f != "" {
					return f
				}
			}
		}
	}
	return "Fira Code"
}

func fcMatchFile(family string) string {
	out, err := exec.Command("fc-match", "-f", "%{file}\n", family).Output()
	if err != nil {
		return ""
	}
	return strings.TrimSpace(string(out))
}

func fcMatchFamily(family string) string {
	out, err := exec.Command("fc-match", "-f", "%{family}\n", family).Output()
	if err != nil {
		return ""
	}
	return strings.TrimSpace(string(out))
}

func bundledMonoPath() string {
	runtimes := []string{}
	if dir := os.Getenv("XDG_RUNTIME_DIR"); dir != "" {
		runtimes = append(runtimes, dir)
	}
	if uid := os.Getuid(); uid >= 0 {
		runtimes = append(runtimes, "/run/user/"+strconv.Itoa(uid))
	}
	for _, dir := range runtimes {
		matches, _ := filepath.Glob(filepath.Join(dir, "danklinux-shell", "*", "DCommon", "assets", "fonts", "nerd-fonts", "FiraCodeNerdFont-Regular.ttf"))
		if len(matches) > 0 {
			return matches[0]
		}
	}
	matches, _ := filepath.Glob("/run/user/*/danklinux-shell/*/DCommon/assets/fonts/nerd-fonts/FiraCodeNerdFont-Regular.ttf")
	if len(matches) > 0 {
		return matches[0]
	}
	return ""
}

func resolveHUDFontPath() string {
	family := hudMonoFamily()
	if file := fcMatchFile(family); file != "" {
		if matched := fcMatchFamily(family); matched != "" && strings.Contains(strings.ToLower(matched), strings.ToLower(family)) {
			return file
		}
	}
	if path := bundledMonoPath(); path != "" {
		return path
	}
	if file := fcMatchFile(family); file != "" {
		return file
	}
	if file := fcMatchFile("monospace"); file != "" {
		return file
	}
	return ""
}

func loadHUDFont() (*opentype.Font, error) {
	hudFontOnce.Do(func() {
		path := resolveHUDFontPath()
		if path == "" {
			hudFaceErr = os.ErrNotExist
			return
		}
		data, err := os.ReadFile(path)
		if err != nil {
			hudFaceErr = err
			return
		}
		hudFont, hudFaceErr = opentype.Parse(data)
	})
	return hudFont, hudFaceErr
}

func hudFace(scale int) font.Face {
	hudFaceMu.Lock()
	defer hudFaceMu.Unlock()
	px := fontCharH * scale
	if face, ok := hudFaces[px]; ok {
		return face
	}
	f, err := loadHUDFont()
	if err != nil || f == nil {
		return nil
	}
	face, err := opentype.NewFace(f, &opentype.FaceOptions{
		Size:    float64(px),
		DPI:     72,
		Hinting: font.HintingFull,
	})
	if err != nil {
		return nil
	}
	hudFaces[px] = face
	return face
}

func hudAdvance(scale int, fallbackStep int) int {
	if face := hudFace(scale); face != nil {
		if adv, ok := face.GlyphAdvance('0'); ok {
			return adv.Ceil()
		}
	}
	return fallbackStep
}

func hudLineHeight(scale int, fallbackH int) int {
	if face := hudFace(scale); face != nil {
		m := face.Metrics()
		return (m.Ascent + m.Descent).Ceil()
	}
	return fallbackH
}

func hudDrawText(data []byte, stride, bufW, bufH, x, y int, text string, cr, cg, cb uint8, format uint32, scale int) {
	face := hudFace(scale)
	if face == nil {
		return
	}
	c0, c2 := cb, cr
	if formatIsBGR(format) {
		c0, c2 = cr, cb
	}
	img := &image.RGBA{Pix: data, Stride: stride, Rect: image.Rect(0, 0, bufW, bufH)}
	m := face.Metrics()
	d := &font.Drawer{
		Dst:  img,
		Src:  image.NewUniform(color.RGBA{c0, cg, c2, 255}),
		Face: face,
		Dot:  fixed.P(x, y+m.Ascent.Ceil()),
	}
	d.DrawString(text)
}
