use clap::Parser;
mod day19 {
    pub mod solution1;
}

#[derive(Parser, Debug)]
#[command(version, about, long_about = None)]
struct Args {
    #[arg(short, long)]
    day: i32,
    #[arg(short, long)]
    solution: i32,
    #[arg(short, long)]
    input: String,
}

fn main() {
    let args = Args::parse();
    match (args.day, args.solution) {
        (19, 1) => day19::solution1::solution(args.input),
        _ => panic!("Unknown day or solution"),
    }
}
