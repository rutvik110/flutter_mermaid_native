use merman::render::HeadlessRenderer;

pub fn render_mermaid_to_svg(diagram: String) -> String {
    let processed = preprocess_diagram(&diagram);
    let renderer = HeadlessRenderer::new();

    renderer
        .render_svg_readable_sync(&processed)
        .expect("Failed to render diagram")
        .expect("No SVG output")
}

pub fn render_mermaid_to_png(diagram: String) -> Vec<u8> {
    let svg = render_mermaid_to_svg(diagram);
    svg_to_png(&svg)
}

/// Sanitizes diagram source to work around known merman parser limitations.
///
/// merman's `lex_descr` stops at `:` characters, so a label like
/// `Streaming (isLastNode: true)` gets split into two Descr tokens.
/// This replaces secondary colons within transition labels with ` -`.
fn preprocess_diagram(diagram: &str) -> String {
    let trimmed = diagram.trim_start();
    if !trimmed.starts_with("stateDiagram") {
        return diagram.to_string();
    }

    diagram
        .lines()
        .map(|line| {
            if let Some(colon_pos) = line.find(':') {
                let (before, label_with_colon) = line.split_at(colon_pos);
                let label = &label_with_colon[1..]; // skip the first ':'
                let sanitized_label = label.replace(':', " -");
                format!("{}:{}", before, sanitized_label)
            } else {
                line.to_string()
            }
        })
        .collect::<Vec<_>>()
        .join("\n")
}

fn svg_to_png(svg: &str) -> Vec<u8> {
    use resvg::tiny_skia::{Pixmap, Transform};
    use resvg::usvg::{Options, Tree};

    let mut opt = Options::default();
    opt.fontdb_mut().load_system_fonts();

    let tree = Tree::from_str(svg, &opt).expect("Failed to parse SVG");
    let size = tree.size().to_int_size();

    let scale = 2.0;
    let width = (size.width() as f32 * scale) as u32;
    let height = (size.height() as f32 * scale) as u32;

    let mut pixmap = Pixmap::new(width, height).expect("Failed to create pixmap");
    pixmap.fill(resvg::tiny_skia::Color::WHITE);

    resvg::render(&tree, Transform::from_scale(scale, scale), &mut pixmap.as_mut());

    pixmap.encode_png().expect("Failed to encode PNG")
}

#[flutter_rust_bridge::frb(init)]
pub fn init_app() {
    flutter_rust_bridge::setup_default_user_utils();
}
