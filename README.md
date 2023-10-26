# UVI Falcon Scripts 
## by Roy Klein (https://www.instagram.com/memento.eternum/)

If you make use of the Scripts please let me know! It motivates me to make more.

## PseudoRandom arp

The purpose of this arp is to generate random yet reproducible melodies on the fly. Reproducible means that you won't get different melodies every time you use the arp, allowing you to build parts, melodies and jams with predictable outcomes.

### Note Length

The length given to each note. Quarter note, half note, etc.

### Beat

Beat division value. For example, 4 means 1/4th note. When this is changed during playtime, the script will wait for the next beat before starting the arp again, to prevent the melody from going off beat.

### Length

Length of the melody in notes. Maximum is 16, but the script can support longer melodies by modifying the `melodyMaximumLength` variable. You can modify this parameter freely while the arp is playing to create some rhythmic variations.

### OffChance

Every note is assigned a random number between 2 and 20. If Offchance is lower than that number, the note will play. This means that when OffChance is at 1, all notes will play, and OffChance at 20 will mean no notes will play. The higher the value of OffChance, the more sparse the melody. 

This value is overridden by the step sequencer.

You can modify this parameter freely

### Melody

A collection of 10 pseudorandom melodies to choose from. You can change this knob freely while the arp is running to change and variate the played melody.

### Seed

Every seed value generates a different collection of 10 melodies. With seed going from 1-100, and 10 melodies for each, the arp supports 1000 unique melodies. For additional variation, you can change the notes going into the arp.

### Sequencer

These rows of buttons indicates which notes in the melody are forced to play. This overrides "OffChance". For example, you can fix which notes play by turning OffChance to 20 (all notes are off), and turning off some notes in the sequencer (which overrides OffChance). The Sequencer will dynamically disable buttons representing notes outside the melody length.

----------------------------------------------

For bug reports/feature requests please use github

All Scripts are released under LGPL 3.0 License. 
