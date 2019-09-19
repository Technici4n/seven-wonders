msdf-bmfont -t sdf -o Ubuntu-R.png -f json --pot -s 128  Ubuntu-R.ttf -r 16 -i charset.txt 
python correct_json.py
python find_inside_point.py
python flip.py
cp Ubuntu-R.json ../backend/static/font.json
cp Ubuntu-R.png ../backend/static/font.png
