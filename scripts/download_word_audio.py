import csv
import os
import time
from gtts import gTTS

def main():
    csv_path = 'assets/common_words.csv'
    out_dir = 'assets/audio/words'
    
    os.makedirs(out_dir, exist_ok=True)
    
    with open(csv_path, 'r', encoding='utf-8') as f:
        reader = csv.reader(f)
        header = next(reader)
        
        for i, row in enumerate(reader):
            if not row or len(row) < 3:
                continue
            
            arabic_text = row[0].strip()
            # Special case for Farsi characters used in the CSV sometimes
            arabic_text = arabic_text.replace('ک', 'ك').replace('ی', 'ي')
            
            # 0-indexed for the audio files (row 1 is 0.mp3)
            out_file = os.path.join(out_dir, f"{i}.mp3")
            
            if not os.path.exists(out_file):
                print(f"Generating {out_file} for '{arabic_text}'...")
                tts = gTTS(text=arabic_text, lang='ar')
                tts.save(out_file)
                time.sleep(0.5) # Be nice to the API
            
    print("Done generating all audio files!")

if __name__ == '__main__':
    main()
