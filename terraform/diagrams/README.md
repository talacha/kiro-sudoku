# Architecture Diagrams

Mermaid diagrams of the S3 + CloudFront Terraform application. Both files are
validated as syntactically correct Mermaid and are importable into draw.io.

## Files

| File                          | Mermaid type         | Icons                                   |
| ----------------------------- | -------------------- | --------------------------------------- |
| `architecture.mmd`            | `architecture-beta`  | Real AWS logo icons (via `logos:` pack) |
| `architecture-flowchart.mmd`  | `flowchart`          | AWS brand-colored nodes (max compat)    |

Two versions are provided because `architecture-beta` renders true AWS icons but is
a newer Mermaid feature; the `flowchart` version renders everywhere draw.io's Mermaid
plugin runs. Prefer `architecture.mmd` if your tool supports icon packs.

## Icon choices (requirement #1)

Icons were chosen to match the actual Terraform resources:

| Component                         | Terraform resource                        | Icon used                 |
| --------------------------------- | ----------------------------------------- | ------------------------- |
| CloudFront distribution           | `aws_cloudfront_distribution`             | `logos:aws-cloudfront`    |
| Origin Access Control (OAC)       | `aws_cloudfront_origin_access_control`    | `logos:aws-iam` (auth)*   |
| Private S3 bucket                 | `aws_s3_bucket` (+ policy, PAB, SSE)      | `logos:aws-s3`            |
| Viewer                            | n/a (client)                              | generic `internet` icon*  |

\* Requirement #3: OAC and the end-user viewer have no dedicated Mermaid logo. Per the
instruction to fall back to a generic icon when unsure, OAC uses the IAM/auth icon
(closest AWS security concept) and the viewer uses the generic internet/browser icon.
Terraform itself has no first-class Mermaid icon pack entry; the diagram models the
*deployed AWS architecture* rather than Terraform internals.

## Transparent background (requirement #4)

- `architecture-flowchart.mmd` sets `themeVariables.background: transparent` in its
  init header and all subgraph containers use `fill:transparent`.
- When exporting with the Mermaid CLI, pass `-b transparent`.
- In draw.io, the canvas is transparent by default on export (uncheck any
  background color in **File → Export As → PNG/SVG**).

## Loading into draw.io

1. Open <https://app.diagrams.net> (or the desktop app).
2. **Extras / Arrange → Insert → Advanced → Mermaid...**
   (menu wording varies by version; also under **+ (Insert) → Advanced → Mermaid**).
3. Paste the contents of a `.mmd` file.
4. Click **Insert**. The diagram becomes editable shapes.

If `architecture.mmd` (icon version) does not render in your draw.io build, use
`architecture-flowchart.mmd` instead.

## Architecture summary

```
Viewer --HTTPS--> CloudFront --(OAC, SigV4)--> Private S3 bucket
```

- All S3 public access is blocked; the bucket policy trusts only this CloudFront
  distribution (`AWS:SourceArn` condition).
- CloudFront serves `sudoku.html` as the default root object over HTTPS.
