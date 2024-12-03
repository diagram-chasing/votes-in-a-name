import pandas as pd
import google.generativeai as genai
from tqdm import tqdm
import time
import json
from dotenv import load_dotenv
import os

load_dotenv()
genai.configure(api_key=os.getenv('GEMINI_API_KEY'))
model = genai.GenerativeModel("gemini-1.5-flash")

def get_transliterations_and_similarity(ref_name, dummy_name, state):
    """Get Hindi and regional transliterations using Gemini API and check name similarity"""
    prompt = f"""
Task: Compare these two Indian names from {state} state:
1. Reference name: "{ref_name}"
2. Dummy name: "{dummy_name}"

Provide:
1. Transliterations for both names in:
   - Hindi (Devanagari)
   - The primary regional language script of {state}
2. Analyze if these specific names could be confused with each other if they are on the same ballot.

Consider these specific aspects:
- Visual similarity in writing (both scripts)
- Sound/pronunciation similarity
- Overall perception by voters

Rules for determining confusion:
- Names must share significant parts (not just common prefixes like 'VIJAY' or 'RAM')
- Consider voter confusion in a ballot context
- Single-word vs multi-word name differences are significant
- Different middle names or initials make names distinct
- Common surname matches alone are not enough (e.g., 'SINGH', 'KUMAR')

Rules for output:
- Return ONLY a JSON with exactly this format, no other text:
{{
    "reference": {{"hindi": "hindi_trans", "regional": "regional_trans"}},
    "dummy": {{"hindi": "hindi_trans", "regional": "regional_trans"}},
    "potentially_confusing": true_or_false,
    "confusion_type": ["VISUAL", "SOUND", "PERCEPTION", "NOT_CONFUSING"],
    "confusion_score": 0.0 to 1.0
}}
- If the state's primary language uses Devanagari script, return the same as hindi for regional
- For confusion_type: include only if similarity exists in that category
- For confusion_score: 
  * 0.0-0.3: Not confusing
  * 0.4-0.6: Somewhat confusing
  * 0.7-0.9: Very confusing
  * 1.0: Identical
- Set potentially_confusing to true ONLY if confusion_score >= 0.7
"""
    
    # Add special handling for identical names
    if ref_name == dummy_name:
        return (
            None,  # ref_hindi
            None,  # ref_regional
            None,  # dummy_hindi
            None,  # dummy_regional
            True,  # potentially_confusing
            ["VISUAL", "SOUND", "PERCEPTION"],  # confusion_type
            1.0    # confusion_score
        )
    
    try:
        response = model.generate_content(
            prompt,
            generation_config={
                'temperature': 0.1,  
                'response_mime_type': 'application/json'
            }
        )
        
        # Extract and parse the JSON response
        text = response.text
        cleaned_text = text.strip().strip('`').strip()
        if cleaned_text.startswith('json'):
            cleaned_text = cleaned_text[4:].strip()
        
        # Add additional JSON cleaning
        cleaned_text = cleaned_text.replace('\\', '\\\\')
            
        result = json.loads(cleaned_text)
        return (
            result["reference"]["hindi"], 
            result["reference"]["regional"],
            result["dummy"]["hindi"],
            result["dummy"]["regional"],
            result["potentially_confusing"],
            result["confusion_type"],
            result["confusion_score"]
        )
        
    except Exception as e:
        print(f"Error processing names {ref_name} and {dummy_name} from {state}: {str(e)}")
        time.sleep(1)
        return None, None, None, None, None, None, None

def process_names_in_batches(input_file, output_file, batch_size=10, sample_size=None):
    """Process names in batches to respect rate limits"""
    
  
    df = pd.read_csv(input_file)
    if sample_size:
        df = df.sample(n=sample_size, random_state=42)
    
    # Check if output file exists and load processed entries
    processed_entries = set()
    if os.path.exists(output_file):
        existing_df = pd.read_csv(output_file)
        processed_entries = set(zip(existing_df['ref_name'], existing_df['dummy_name'], existing_df['state']))
        
    # Filter out already processed entries
    df = df[~df.apply(lambda row: (row['Ref_Candidate'], row['Dummy_Candidate'], row['State_Name'].replace('_', ' ')) 
                      in processed_entries, axis=1)]
    
    print(f"Resuming processing with {len(df)} remaining entries...")
    
    results = []
    batches = [df[i:i + batch_size] for i in range(0, len(df), batch_size)]
    
    try:
        with tqdm(total=len(df)) as pbar:
            for batch in batches:
                batch_results = []
                
                for _, row in batch.iterrows():
                    ref_name = row['Ref_Candidate']
                    dummy_name = row['Dummy_Candidate']
                    state = row['State_Name'].replace('_', ' ')
                    
                    retries = 3
                    result = None
                    while retries > 0:
                        try:
                            result = get_transliterations_and_similarity(ref_name, dummy_name, state)
                            if all(x is not None for x in result):
                                batch_results.append({
                                    'ref_name': ref_name,
                                    'dummy_name': dummy_name,
                                    'state': state,
                                    'ref_hindi': result[0],
                                    'ref_regional': result[1],
                                    'dummy_hindi': result[2],
                                    'dummy_regional': result[3],
                                    'potentially_confusing': result[4],
                                    'confusion_type': result[5],
                                    'confusion_score': result[6]
                                })
                                break
                            retries -= 1
                            time.sleep(2)  # Increased delay between retries
                        except Exception as e:
                            print(f"\nError processing {ref_name} and {dummy_name}: {str(e)}")
                            retries -= 1
                            time.sleep(2)  # Increased delay between retries
                    
                    if result is None:
                        print(f"\nSkipping pair after all retries: {ref_name} and {dummy_name}")
                    
                    pbar.update(1)
                
                # Add batch results
                results.extend(batch_results)
                
                # Save intermediate results after each batch
                if batch_results:  # Only save if we have new results
                    if os.path.exists(output_file):
                        existing_df = pd.read_csv(output_file)
                        updated_df = pd.concat([existing_df, pd.DataFrame(batch_results)], ignore_index=True)
                    else:
                        updated_df = pd.DataFrame(batch_results)
                    updated_df.to_csv(output_file, index=False)
                
                # Rate limit delay between batches
                time.sleep(2)
                
    except KeyboardInterrupt:
        print("\nProcess interrupted by user. Saving current progress...")
        if results:  # Save any remaining results
            if os.path.exists(output_file):
                existing_df = pd.read_csv(output_file)
                updated_df = pd.concat([existing_df, pd.DataFrame(results)], ignore_index=True)
            else:
                updated_df = pd.DataFrame(results)
            updated_df.to_csv(output_file, index=False)
        print("Progress saved. You can resume later from where you left off.")
        return
    
    print(f"\nProcessing complete. Results saved to {output_file}")

def main():
    input_file = "../copycat_candidates_full.csv"
    
    # Ask user for mode
    mode = input("Run on sample (s) or full dataset (f)? ").lower()
    
    if mode == 's':
        sample_size = int(input("Enter sample size: "))
        output_file = "../name_transliterations_sample.csv"
        process_names_in_batches(input_file, output_file, sample_size=sample_size)
    elif mode == 'f':
        output_file = "../name_transliterations_full.csv"
        process_names_in_batches(input_file, output_file)
    else:
        print("Invalid mode selected")

if __name__ == "__main__":
    main()