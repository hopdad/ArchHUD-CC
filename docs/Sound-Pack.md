# Sound Pack

ArchHUD supports audio feedback through customizable sound files.

## Installation

1. Download the sound files from the sound pack link.
2. Extract to your `Documents\NQ\DualUniverse\audio` folder (create the `audio` subfolder if it does not exist).
3. You should now have an `archHUD` subfolder containing all the sound files.
4. **Important**: Rename the `archHUD` subfolder to something personal. This prevents other players from triggering sounds on your computer.
5. Set the `soundFolder` user variable to your chosen folder name:
   ```
   /G soundFolder yourname
   ```

## Controls

| Key / Variable | Description |
|----------------|-------------|
| `Alt-7` | Toggle all sounds on/off |
| `voices` (default: true) | Set to false to disable voice sounds |
| `alerts` (default: true) | Set to false to disable alert sounds |

## Customization

- Any sound file can be replaced with a different `.mp3` using the same filename.
- To remove a specific sound without replacing it, simply delete its `.mp3` file from the folder.
- The remaining sounds will continue to work normally.

## Alternative Sound Pack

The repository includes a community sound pack: `archHUD_Mia_soundpack_by_W1zard.zip`
