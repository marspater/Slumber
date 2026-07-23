import math
import os

def superellipse_path(cx, cy, a, b, n=5, num_points=120):
    points = []
    for i in range(num_points):
        theta = (2 * math.pi * i) / num_points
        cos_t = math.cos(theta)
        sin_t = math.sin(theta)
        sgn_x = 1 if cos_t >= 0 else -1
        sgn_y = 1 if sin_t >= 0 else -1
        x = cx + a * sgn_x * (abs(cos_t) ** (2.0 / n))
        y = cy + b * sgn_y * (abs(sin_t) ** (2.0 / n))
        points.append((x, y))
    path_d = f"M {points[0][0]:.2f} {points[0][1]:.2f}"
    for pt in points[1:]:
        path_d += f" L {pt[0]:.2f} {pt[1]:.2f}"
    path_d += " Z"
    return path_d

def generate_svg():
    outer_sq_d = superellipse_path(512, 512, 456, 456, n=5, num_points=180)
    glass_sq_d = superellipse_path(512, 520, 310, 310, n=5, num_points=180)
    glass_inner_d = superellipse_path(512, 520, 308, 308, n=5, num_points=180)

    svg_content = f'''<svg width="1024" height="1024" viewBox="0 0 1024 1024" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <!-- Background Cosmic Gradients -->
    <radialGradient id="spaceBg" cx="50%" cy="30%" r="85%">
      <stop offset="0%" stop-color="#4c2a9e"/>
      <stop offset="35%" stop-color="#2a145a"/>
      <stop offset="70%" stop-color="#120833"/>
      <stop offset="100%" stop-color="#070216"/>
    </radialGradient>
    
    <!-- Nebula Glows -->
    <radialGradient id="nebula1" cx="75%" cy="25%" r="50%">
      <stop offset="0%" stop-color="#8c52ff" stop-opacity="0.55"/>
      <stop offset="60%" stop-color="#562bbd" stop-opacity="0.2"/>
      <stop offset="100%" stop-color="#120833" stop-opacity="0"/>
    </radialGradient>
    <radialGradient id="nebula2" cx="25%" cy="75%" r="55%">
      <stop offset="0%" stop-color="#3d72ff" stop-opacity="0.45"/>
      <stop offset="60%" stop-color="#6935d9" stop-opacity="0.15"/>
      <stop offset="100%" stop-color="#070216" stop-opacity="0"/>
    </radialGradient>
    <radialGradient id="nebulaCenter" cx="50%" cy="50%" r="40%">
      <stop offset="0%" stop-color="#9a65ff" stop-opacity="0.35"/>
      <stop offset="100%" stop-color="#9a65ff" stop-opacity="0"/>
    </radialGradient>

    <!-- Glass Card Gradients & Filters -->
    <linearGradient id="glassGrad" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#ffffff" stop-opacity="0.32"/>
      <stop offset="30%" stop-color="#ffffff" stop-opacity="0.18"/>
      <stop offset="70%" stop-color="#ffffff" stop-opacity="0.08"/>
      <stop offset="100%" stop-color="#ffffff" stop-opacity="0.22"/>
    </linearGradient>
    <linearGradient id="glassStroke" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#ffffff" stop-opacity="0.85"/>
      <stop offset="25%" stop-color="#ffffff" stop-opacity="0.45"/>
      <stop offset="60%" stop-color="#ffffff" stop-opacity="0.15"/>
      <stop offset="100%" stop-color="#ffffff" stop-opacity="0.65"/>
    </linearGradient>
    <linearGradient id="glassGlare" x1="0%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%" stop-color="#ffffff" stop-opacity="0.4"/>
      <stop offset="100%" stop-color="#ffffff" stop-opacity="0.0"/>
    </linearGradient>

    <!-- Filters for Ambient Glass Glow & Soft Shadows -->
    <filter id="glassShadow" x="-20%" y="-20%" width="140%" height="140%">
      <feDropShadow dx="0" dy="16" stdDeviation="24" flood-color="#000000" flood-opacity="0.45"/>
      <feDropShadow dx="0" dy="4" stdDeviation="8" flood-color="#3b1689" flood-opacity="0.4"/>
    </filter>
    <filter id="starSparkleGlow" x="-50%" y="-50%" width="200%" height="200%">
      <feGaussianBlur stdDeviation="3" result="blur"/>
      <feMerge>
        <feMergeNode in="blur"/>
        <feMergeNode in="SourceGraphic"/>
      </feMerge>
    </filter>

    <!-- Original Moon Gradients -->
    <radialGradient id="moonGlow" cx="50%" cy="60%" r="50%">
      <stop offset="0%" stop-color="#e5e6ff" stop-opacity="0.98"/>
      <stop offset="80%" stop-color="#a187e6" stop-opacity="0.15"/>
      <stop offset="100%" stop-color="#252442" stop-opacity="0.04"/>
    </radialGradient>
    <linearGradient id="crescentGrad" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0%" stop-color="#fffbe9"/>
      <stop offset="100%" stop-color="#d1b6fa"/>
    </linearGradient>
    <radialGradient id="starGlow" cx="50%" cy="50%" r="80%">
      <stop offset="0%" stop-color="#fff" stop-opacity="0.95"/>
      <stop offset="100%" stop-color="#fff" stop-opacity="0"/>
    </radialGradient>
  </defs>

  <!-- ================= BACKGROUND SQUIRCLE (n=5 Superellipse) ================= -->
  <path d="{outer_sq_d}" fill="url(#spaceBg)"/>
  <path d="{outer_sq_d}" fill="url(#nebula1)"/>
  <path d="{outer_sq_d}" fill="url(#nebula2)"/>
  <path d="{outer_sq_d}" fill="url(#nebulaCenter)"/>

  <!-- Background Stars & Sparkles -->
  <g transform="translate(730, 220)" filter="url(#starSparkleGlow)">
    <path d="M 0 -22 Q 0 0 22 0 Q 0 0 0 22 Q 0 0 -22 0 Q 0 0 0 -22 Z" fill="#ffffff" opacity="0.9"/>
    <circle cx="0" cy="0" r="14" fill="url(#starGlow)" opacity="0.6"/>
  </g>
  <g transform="translate(240, 240)">
    <path d="M 0 -12 Q 0 0 12 0 Q 0 0 0 12 Q 0 0 -12 0 Q 0 0 0 -12 Z" fill="#ffffff" opacity="0.6"/>
  </g>
  <g transform="translate(180, 430)">
    <path d="M 0 -16 Q 0 0 16 0 Q 0 0 0 16 Q 0 0 -16 0 Q 0 0 0 -16 Z" fill="#ffffff" opacity="0.75"/>
  </g>
  <g transform="translate(800, 630)">
    <path d="M 0 -14 Q 0 0 14 0 Q 0 0 0 14 Q 0 0 -14 0 Q 0 0 0 -14 Z" fill="#ffffff" opacity="0.65"/>
  </g>
  <circle cx="770" cy="280" r="3.5" fill="#ffffff" opacity="0.7"/>
  <circle cx="280" cy="300" r="3" fill="#ffffff" opacity="0.5"/>
  <circle cx="820" cy="380" r="2.5" fill="#ffffff" opacity="0.6"/>
  <circle cx="220" cy="650" r="4" fill="#ffffff" opacity="0.5"/>

  <!-- ================= CENTRAL FROSTED GLASS CARD (n=5 Superellipse) ================= -->
  <g filter="url(#glassShadow)">
    <path d="{glass_sq_d}" fill="url(#glassGrad)"/>
    <path d="{glass_sq_d}" fill="none" stroke="url(#glassStroke)" stroke-width="4.5"/>
    <path d="{glass_inner_d}" fill="none" stroke="#ffffff" stroke-width="1.5" opacity="0.3"/>
  </g>

  <!-- Top Glass Reflection Glare -->
  <path d="{glass_sq_d}" fill="url(#glassGlare)" opacity="0.25"/>

  <!-- ================= ORIGINAL MOON ELEMENTS ================= -->
  <!-- Moon face -->
  <circle cx="520" cy="530" r="180" fill="url(#moonGlow)"/>
  <!-- Crescent overlay -->
  <ellipse cx="590" cy="460" rx="56" ry="48" fill="url(#crescentGrad)" opacity="0.85"/>
  <ellipse cx="603" cy="455" rx="40" ry="41" fill="#b1a5e6" opacity="0.08"/>
  <!-- Moon face features -->
  <ellipse cx="537" cy="560" rx="19" ry="8" fill="#fff" opacity="0.18"/>
  <path d="M480,550 Q520,590 560,550" stroke="#a889d9" stroke-width="8" fill="none" opacity="0.8"/>
  <path d="M482,523 Q492,537 502,522" stroke="#a889d9" stroke-width="7" fill="none" opacity="0.8"/>
  <path d="M538,522 Q547,537 557,523" stroke="#a889d9" stroke-width="7" fill="none" opacity="0.8"/>
  <!-- Sparkle stars -->
  <circle cx="645" cy="370" r="9" fill="url(#starGlow)" opacity="0.9"/>
  <circle cx="670" cy="400" r="5" fill="url(#starGlow)" opacity="0.7"/>
  <circle cx="588" cy="398" r="4" fill="url(#starGlow)" opacity="0.6"/>
  <circle cx="600" cy="340" r="7" fill="url(#starGlow)" opacity="0.7"/>
  <!-- Subtle highlight -->
  <ellipse cx="490" cy="480" rx="54" ry="22" fill="#fff" opacity="0.13"/>

</svg>
'''
    with open("/Users/marspater/Projects/Sleeper/FutureIconAsset.svg", "w") as f:
        f.write(svg_content)

if __name__ == "__main__":
    generate_svg()
