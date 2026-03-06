use merman::render::HeadlessRenderer;

pub fn render_mermaid_to_svg(diagram: String) -> String {
    let renderer = HeadlessRenderer::new();

    renderer
        .render_svg_readable_sync(&diagram)
        .expect("Failed to render diagram")
        .expect("No SVG output")
}

pub fn render_mermaid_to_png(diagram: String) -> Vec<u8> {
    let svg = render_mermaid_to_svg(diagram);
    svg_to_png(&svg)
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
