import math

def superellipse_path(cx, cy, a, b, n=5, num_points=180):
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
    # Outer squircle bounds (Apple continuous corners n=5)
    outer_sq_d = superellipse_path(512, 512, 456, 456, n=5, num_points=240)
    
    # Glass card squircle bounds (centered at 512, 512, size 720x720 -> a=360, b=360)
    glass_sq_d = superellipse_path(512, 512, 360, 360, n=5, num_points=240)
    glass_inner_d = superellipse_path(512, 512, 356, 356, n=5, num_points=240)

    svg_content = f'''<svg width="1024" height="1024" viewBox="0 0 1024 1024" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <!-- Background Space Gradient -->
    <radialGradient id="spaceBg" cx="50%" cy="30%" r="85%">
      <stop offset="0%" stop-color="#3d227a"/>
      <stop offset="35%" stop-color="#23124d"/>
      <stop offset="70%" stop-color="#0e0624"/>
      <stop offset="100%" stop-color="#050212"/>
    </radialGradient>
    
    <!-- Nebulae -->
    <radialGradient id="nebulaTopRight" cx="75%" cy="20%" r="55%">
      <stop offset="0%" stop-color="#834beb" stop-opacity="0.6"/>
      <stop offset="60%" stop-color="#562bbd" stop-opacity="0.25"/>
      <stop offset="100%" stop-color="#0e0624" stop-opacity="0"/>
    </radialGradient>
    <radialGradient id="nebulaBottomLeft" cx="20%" cy="80%" r="55%">
      <stop offset="0%" stop-color="#2c62eb" stop-opacity="0.5"/>
      <stop offset="60%" stop-color="#6935d9" stop-opacity="0.2"/>
      <stop offset="100%" stop-color="#050212" stop-opacity="0"/>
    </radialGradient>

    <!-- Glass Box Gradients & Filters -->
    <linearGradient id="glassGrad" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#ffffff" stop-opacity="0.26"/>
      <stop offset="35%" stop-color="#ffffff" stop-opacity="0.12"/>
      <stop offset="75%" stop-color="#ffffff" stop-opacity="0.06"/>
      <stop offset="100%" stop-color="#ffffff" stop-opacity="0.20"/>
    </linearGradient>
    <linearGradient id="glassBorder" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#ffffff" stop-opacity="0.9"/>
      <stop offset="30%" stop-color="#ffffff" stop-opacity="0.45"/>
      <stop offset="70%" stop-color="#ffffff" stop-opacity="0.2"/>
      <stop offset="100%" stop-color="#ffffff" stop-opacity="0.75"/>
    </linearGradient>
    <linearGradient id="glassGlare" x1="0%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%" stop-color="#ffffff" stop-opacity="0.35"/>
      <stop offset="100%" stop-color="#ffffff" stop-opacity="0.0"/>
    </linearGradient>

    <!-- Main Moon Face Spherical Gradient -->
    <radialGradient id="moonGrad" cx="35%" cy="30%" r="75%">
      <stop offset="0%" stop-color="#6bbdfd"/>
      <stop offset="40%" stop-color="#5595f8"/>
      <stop offset="75%" stop-color="#8753f7"/>
      <stop offset="100%" stop-color="#a64ef5"/>
    </radialGradient>

    <!-- Crescent Moon Gradient -->
    <linearGradient id="crescentGrad" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#f3ebff"/>
      <stop offset="45%" stop-color="#cc9eff"/>
      <stop offset="100%" stop-color="#a269f7"/>
    </linearGradient>

    <!-- Sparkle Glow Filter -->
    <filter id="starGlow" x="-50%" y="-50%" width="200%" height="200%">
      <feGaussianBlur stdDeviation="3" result="blur"/>
      <feMerge>
        <feMergeNode in="blur"/>
        <feMergeNode in="SourceGraphic"/>
      </feMerge>
    </filter>
    <filter id="moonGlow" x="-30%" y="-30%" width="160%" height="160%">
      <feDropShadow dx="0" dy="0" stdDeviation="25" flood-color="#549bfa" flood-opacity="0.45"/>
      <feDropShadow dx="0" dy="0" stdDeviation="45" flood-color="#9a4ef5" flood-opacity="0.35"/>
    </filter>
    <filter id="glassShadow" x="-20%" y="-20%" width="140%" height="140%">
      <feDropShadow dx="0" dy="18" stdDeviation="28" flood-color="#000000" flood-opacity="0.5"/>
      <feDropShadow dx="0" dy="4" stdDeviation="10" flood-color="#3b1689" flood-opacity="0.4"/>
    </filter>
  </defs>

  <!-- ================= BACKGROUND SQUIRCLE ================= -->
  <path d="{outer_sq_d}" fill="url(#spaceBg)"/>
  <path d="{outer_sq_d}" fill="url(#nebulaTopRight)"/>
  <path d="{outer_sq_d}" fill="url(#nebulaBottomLeft)"/>

  <!-- Cosmic Stars & Sparkles -->
  <g transform="translate(800, 220)" filter="url(#starGlow)">
    <path d="M 0 -22 Q 0 0 22 0 Q 0 0 0 22 Q 0 0 -22 0 Q 0 0 0 -22 Z" fill="#ffffff" opacity="0.9"/>
  </g>
  <g transform="translate(180, 220)" filter="url(#starGlow)">
    <path d="M 0 -14 Q 0 0 14 0 Q 0 0 0 14 Q 0 0 -14 0 Q 0 0 0 -14 Z" fill="#ffffff" opacity="0.75"/>
  </g>
  <g transform="translate(160, 680)" filter="url(#starGlow)">
    <path d="M 0 -16 Q 0 0 16 0 Q 0 0 0 16 Q 0 0 -16 0 Q 0 0 0 -16 Z" fill="#ffffff" opacity="0.8"/>
  </g>
  <g transform="translate(840, 700)" filter="url(#starGlow)">
    <path d="M 0 -15 Q 0 0 15 0 Q 0 0 0 15 Q 0 0 -15 0 Q 0 0 0 -15 Z" fill="#ffffff" opacity="0.7"/>
  </g>

  <!-- ================= GLASS CARD (n=5 Superellipse) ================= -->
  <g filter="url(#glassShadow)">
    <path d="{glass_sq_d}" fill="url(#glassGrad)"/>
    <path d="{glass_sq_d}" fill="none" stroke="url(#glassBorder)" stroke-width="5"/>
    <path d="{glass_inner_d}" fill="none" stroke="#ffffff" stroke-width="1.8" opacity="0.3"/>
  </g>
  
  <!-- Glass Top Reflection -->
  <path d="{glass_sq_d}" fill="url(#glassGlare)" opacity="0.2"/>

  <!-- ================= CENTER MOON ARTWORK ================= -->
  <g filter="url(#moonGlow)">
    <!-- MAIN SLEEPING MOON (Large & Centered inside glass card) -->
    <circle cx="485" cy="535" r="215" fill="url(#moonGrad)"/>

    <!-- Specular Highlight Curve -->
    <ellipse cx="410" cy="400" rx="110" ry="55" fill="#ffffff" opacity="0.26" transform="rotate(-28 410 400)"/>

    <!-- Main Moon Facial Features -->
    <!-- Left Eye Arc -->
    <path d="M 365 525 Q 410 565 455 525" fill="none" stroke="#251254" stroke-width="11" stroke-linecap="round" opacity="0.85"/>
    <!-- Right Eye Arc -->
    <path d="M 515 525 Q 560 565 605 525" fill="none" stroke="#251254" stroke-width="11" stroke-linecap="round" opacity="0.85"/>

    <!-- Cute Nose -->
    <path d="M 485 538 Q 498 554 485 565" fill="none" stroke="#28145a" stroke-width="7.5" stroke-linecap="round" opacity="0.55"/>

    <!-- Smiling Mouth Arc -->
    <path d="M 440 595 Q 485 635 530 595" fill="none" stroke="#251254" stroke-width="10" stroke-linecap="round" opacity="0.85"/>

    <!-- Rosy Blush Cheeks -->
    <ellipse cx="345" cy="552" rx="24" ry="14" fill="#ff74a4" opacity="0.38"/>
    <ellipse cx="625" cy="552" rx="24" ry="14" fill="#ff74a4" opacity="0.38"/>

    <!-- ATTACHED SLEEPING CRESCENT MOON (Top Right of Head) -->
    <g transform="translate(550, 275)">
      <!-- Smooth Crescent Path -->
      <path d="M 10 15 
               C 65 15 110 60 110 120 
               C 110 170 75 210 25 220 
               C 65 195 85 160 85 120 
               C 85 70 50 30 10 15 Z" 
            fill="url(#crescentGrad)"/>
      
      <!-- Crescent Highlight -->
      <path d="M 20 28 C 65 30 95 65 95 120 C 95 155 78 185 45 202 C 72 182 82 150 82 120 C 82 78 52 42 20 28 Z" 
            fill="#ffffff" opacity="0.38"/>

      <!-- Crescent Sleeping Face -->
      <!-- Eye -->
      <path d="M 52 105 Q 64 117 76 105" fill="none" stroke="#2a145c" stroke-width="5.5" stroke-linecap="round" opacity="0.8"/>
      <!-- Smile -->
      <path d="M 58 132 Q 67 142 76 132" fill="none" stroke="#2a145c" stroke-width="5" stroke-linecap="round" opacity="0.8"/>
      <!-- Blush -->
      <ellipse cx="48" cy="122" rx="7" ry="4.5" fill="#ff74a4" opacity="0.45"/>
    </g>

    <!-- SPARKLE STARS FLOATING AROUND CRESCENT -->
    <g transform="translate(685, 270)" filter="url(#starGlow)">
      <path d="M 0 -22 Q 0 0 22 0 Q 0 0 0 22 Q 0 0 -22 0 Q 0 0 0 -22 Z" fill="#ffffff"/>
    </g>
    <g transform="translate(540, 280)" filter="url(#starGlow)">
      <path d="M 0 -14 Q 0 0 14 0 Q 0 0 0 14 Q 0 0 -14 0 Q 0 0 0 -14 Z" fill="#ffffff" opacity="0.95"/>
    </g>
    <g transform="translate(725, 360)" filter="url(#starGlow)">
      <path d="M 0 -12 Q 0 0 12 0 Q 0 0 0 12 Q 0 0 -12 0 Q 0 0 0 -12 Z" fill="#ffffff" opacity="0.9"/>
    </g>
    <g transform="translate(735, 420)" filter="url(#starGlow)">
      <path d="M 0 -10 Q 0 0 10 0 Q 0 0 0 10 Q 0 0 -10 0 Q 0 0 0 -10 Z" fill="#ffffff" opacity="0.85"/>
    </g>
  </g>
</svg>
'''
    with open("FutureIconAsset.svg", "w") as f:
        f.write(svg_content)
    print("Generated FutureIconAsset.svg (exact vector artwork matching reference) successfully!")

if __name__ == "__main__":
    generate_svg()
