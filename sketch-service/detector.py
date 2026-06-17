"""
Core line-detection logic for the sketch digitizer.

What this does (and does NOT do):
- Isolates thick, dark, continuous strokes from thin text/annotations using
  erosion (proven in prototyping against a real surveyor sketch).
- Uses Hough Line Transform to detect straight segments, including across
  dashed-line gaps.
- Merges collinear/duplicate segments into single edges per side.

What this does NOT do:
- It does NOT know which detected line is "the lot boundary" vs "a house
  outline" vs "a fence" -- it returns ALL strong straight lines it finds,
  ranked by length. The client (Flutter) shows these as suggestions and the
  farmer picks/edits which ones are real boundary edges.
- It does NOT detect curves/arcs at all. Curved boundary segments must be
  added manually by the farmer.
- It is tuned against one sample image style (clean printed surveyor plan).
  Messy handwritten farmer sketches WILL perform worse. This is a starting
  point for the farmer, not an authoritative answer.
"""
import cv2
import numpy as np


def detect_boundary_lines(image_bytes: bytes, min_length: int = 90):
    """
    Returns a list of candidate straight edges detected in the image.
    Each edge is a dict: {x1, y1, x2, y2, length}
    Coordinates are in original image pixel space.
    """
    nparr = np.frombuffer(image_bytes, np.uint8)
    img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
    if img is None:
        raise ValueError("Could not decode image")

    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

    # isolate dark pixels (works for black/navy boundary lines on white background)
    _, dark_mask = cv2.threshold(gray, 90, 255, cv2.THRESH_BINARY_INV)

    # erode to remove thin text/annotation lines, keep thick strokes
    kernel = np.ones((5, 5), np.uint8)
    eroded = cv2.erode(dark_mask, kernel, iterations=1)

    # Hough Line Transform -- finds straight lines even across dash gaps
    lines = cv2.HoughLinesP(
        eroded, 1, np.pi / 180,
        threshold=50, minLineLength=60, maxLineGap=60
    )

    if lines is None:
        return {"width": img.shape[1], "height": img.shape[0], "edges": []}

    segs = [l[0] for l in lines]
    long_segs = [s for s in segs if _length(s) > min_length]

    merged = _merge_collinear(long_segs)

    edges = []
    for p1, p2, length, n_segs in merged:
        edges.append({
            "x1": float(p1[0]), "y1": float(p1[1]),
            "x2": float(p2[0]), "y2": float(p2[1]),
            "length": float(length),
            "confidence": min(1.0, n_segs / 5),  # more merged fragments = more confident it's a real edge
        })

    # sort longest first -- longest edges are most likely to be real boundary, not noise
    edges.sort(key=lambda e: -e["length"])

    return {
        "width": int(img.shape[1]),
        "height": int(img.shape[0]),
        "edges": edges,
    }


def _length(seg):
    return float(np.hypot(seg[2] - seg[0], seg[3] - seg[1]))


def _merge_collinear(segs, angle_tol_deg=6, dist_tol_px=18, min_merged_length=150):
    used = [False] * len(segs)
    groups = []

    for i, s in enumerate(segs):
        if used[i]:
            continue
        group = [s]
        used[i] = True
        ang_i = np.degrees(np.arctan2(s[3] - s[1], s[2] - s[0])) % 180

        for j in range(i + 1, len(segs)):
            if used[j]:
                continue
            s2 = segs[j]
            ang_j = np.degrees(np.arctan2(s2[3] - s2[1], s2[2] - s2[0])) % 180
            if abs(ang_i - ang_j) < angle_tol_deg or abs(abs(ang_i - ang_j) - 180) < angle_tol_deg:
                mx, my = (s2[0] + s2[2]) / 2, (s2[1] + s2[3]) / 2
                denom = _length(s)
                if denom == 0:
                    continue
                d = abs((s[2] - s[0]) * (my - s[1]) - (s[3] - s[1]) * (mx - s[0])) / denom
                if d < dist_tol_px:
                    group.append(s2)
                    used[j] = True
        groups.append(group)

    merged = []
    for g in groups:
        p1, p2 = _fit_line_endpoints(g)
        length = float(np.hypot(p2[0] - p1[0], p2[1] - p1[1]))
        if length > min_merged_length:
            merged.append((p1, p2, length, len(g)))

    return merged


def _fit_line_endpoints(group):
    pts = np.array(
        [[s[0], s[1]] for s in group] + [[s[2], s[3]] for s in group],
        dtype=np.float32
    )
    vx, vy, x0, y0 = cv2.fitLine(pts, cv2.DIST_L2, 0, 0.01, 0.01).flatten()
    t = [(p[0] - x0) * vx + (p[1] - y0) * vy for p in pts]
    tmin, tmax = min(t), max(t)
    p1 = (float(x0 + tmin * vx), float(y0 + tmin * vy))
    p2 = (float(x0 + tmax * vx), float(y0 + tmax * vy))
    return p1, p2