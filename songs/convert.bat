pip install audio-to-midi
for /r %%i in (*.wav) do audio-to-midi -n -t 5000 -a 0.5 %%i 
