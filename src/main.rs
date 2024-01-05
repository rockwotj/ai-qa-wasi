mod qa;

use qa::*;
use tract_onnx::tract_core::anyhow::Result;

use rustyline::error::ReadlineError;
use rustyline::DefaultEditor;

fn main() -> Result<()> {
    let mut rl = DefaultEditor::new()?;
    let content = std::env::var("CONTENT")?;
    let qa = QuestionAnswerer::new_from_disk("./albert/tokenizer.json", "./albert/model.onnx", &content)?;
    loop {
        let readline = rl.readline(">> ");
        match readline {
            Ok(line) => {
                let answer = qa.ask(&line)?;
                println!("Answer: {}", answer.as_ref().map(|a| a.as_str()).unwrap_or("❓"));
            },
            Err(ReadlineError::Interrupted) => {
                break
            },
            Err(ReadlineError::Eof) => {
                break
            },
            Err(err) => {
                eprintln!("Error: {:?}", err);
                break
            }
        }
    }
    Ok(())
}
