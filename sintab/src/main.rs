use std::env;
use std::f64::consts::PI;
use std::fs::File;
use std::io::Write;

fn main() {
    let output_file_name = env::args().skip(1).next().unwrap();

    let bytes =
        (0..256)
        .map(|i| {
            let f = (i as f64) / 128.0 * PI;
            (f.sin() * 64.0/* + (f * 3.0).sin() * 32.0*/) as u8
        })
        .collect::<Vec<_>>();

    let mut output = File::create(output_file_name).unwrap();
    output.write_all(&bytes).unwrap();
}
