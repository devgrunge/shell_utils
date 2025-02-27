import csv
import json
import re
import os
import argparse
from datetime import datetime

def setup_argparse():
    parser = argparse.ArgumentParser(description='Process Facebook group CSV data')
    parser.add_argument('-i', '--input', required=True, help='Caminho para o arquivo CSV de entrada')
    return parser.parse_args()

def ensure_output_dir(csv_path):
    # Cria pasta dist no mesmo diretório do script
    script_dir = os.path.dirname(os.path.realpath(__file__))
    dist_dir = os.path.join(script_dir, 'dist')
    os.makedirs(dist_dir, exist_ok=True)
    
    # Mantém o nome original do arquivo
    base_name = os.path.splitext(os.path.basename(csv_path))[0]
    return os.path.join(dist_dir, f'{base_name}.json')

def clean_url(url):
    return re.sub(r'&__cft__\[.*', '', url) if url else url

def parse_date(date_str):
    formats = [
        ('%b %d', lambda m: datetime.strptime(m.group(), "%b %d").replace(year=datetime.now().year)),
        ('%Y-%m-%d', lambda m: datetime.strptime(m.group(), "%Y-%m-%d"))
    ]
    for fmt, parser in formats:
        date_pattern = datetime.strftime(datetime(2000, 1, 1), fmt).replace('%d', r'\d{2}').replace('%b', r'[A-Za-z]{3}')
        match = re.search(r'\b' + date_pattern + r'\b', date_str)
        if match:
            return parser(match).isoformat()
    return None

def extract_media_links(row):
    media = []
    for cell in row:
        if 'fbcdn.net' in cell or 'youtube.com' in cell or 'ytimg.com' in cell:
            media.append({
                'url': clean_url(cell),
                'type': 'image' if any(ext in cell for ext in ['.jpg', '.png']) else 'video'
            })
    return media

def process_row(row):
    entry = {
        'type': 'post',
        'user': {'name': None, 'role': None, 'profile_url': None},
        'content': [],
        'links': [],
        'media': extract_media_links(row),
        'comments': [],
        'likes': 0,
        'timestamp': None,
        'metadata': {
            'shared_with': 'Public' if any('Shared with Public' in cell for cell in row) else None,
            'group_roles': [],
            'post_url': None
        }
    }

    current_comment = None
    url_pattern = re.compile(r'https?://\S+')

    for i, cell in enumerate(row):
        if not cell.strip():
            continue

        # URL handling
        urls = url_pattern.findall(cell)
        for url in urls:
            clean = clean_url(url)
            if 'facebook.com/groups' in clean:
                entry['metadata']['post_url'] = clean
            elif 'facebook.com/user' in clean:
                entry['user']['profile_url'] = clean
            else:
                entry['links'].append(clean)

        # User identification
        if not entry['user']['name'] and i+1 < len(row):
            if row[i+1] in ['Top contributor', 'Admin', 'Moderator']:
                entry['user']['name'] = cell
                entry['user']['role'] = row[i+1]
                entry['metadata']['group_roles'].append(row[i+1])

        # Content detection
        if cell.startswith('Like'):
            entry['type'] = 'like'
            if i+1 < len(row) and row[i+1].isdigit():
                entry['likes'] = int(row[i+1])
        elif cell.startswith('Comment'):
            entry['type'] = 'comment'
            current_comment = {'text': [], 'author': None}
        elif current_comment:
            if any(role in cell for role in ['Top contributor', 'Admin']):
                current_comment['author'] = cell
            else:
                current_comment['text'].append(cell)
                if len(current_comment['text']) >= 2:
                    entry['comments'].append({
                        'author': current_comment['author'],
                        'text': ' '.join(current_comment['text']),
                        'timestamp': parse_date(cell)
                    })
                    current_comment = None

        # Timestamp
        if not entry['timestamp']:
            entry['timestamp'] = parse_date(cell)

        # Content text
        if cell not in ['Like', 'Comment', 'Admin', 'Moderator'] and not url_pattern.match(cell):
            entry['content'].append(cell)

    # Cleanup
    entry['content'] = ' '.join([c for c in entry['content'] if len(c) > 3]).strip()
    if not entry['media']: del entry['media']
    if not entry['links']: del entry['links']
    
    return entry

def main():
    args = setup_argparse()
    output_file = ensure_output_dir(args.input)
    
    output = []
    with open(args.input, 'r', encoding='utf-8') as f:
        reader = csv.reader(f)
        headers = next(reader)
        
        current_post = None
        for row in reader:
            entry = process_row(row)
            
            if entry['type'] == 'post':
                current_post = entry
                output.append(current_post)
            elif entry['type'] == 'comment' and current_post:
                current_post['comments'].append(entry)
            else:
                output.append(entry)

    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(output, f, indent=2, ensure_ascii=False)

    print(f"Arquivo processado com sucesso: {output_file}")

if __name__ == '__main__':
    main()