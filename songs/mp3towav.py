import pydub
import sys

print(sys.argv)
sound = pydub.AudioSegment.from_mp3(sys.argv[1])
sound.export(sys.argv[2], format="wav")