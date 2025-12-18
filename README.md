# HyprRice
<img width="1920" height="1080" alt="hyprshot" src="https://github.com/honkingpill/HyprRice/images/hyprshot.png" />
Here's my ricing. im still working at configs. also gonna add configs for soft inside my rice
Until i'm fully satisfied with my process - i'm not gonna add install guide and/or full showcase of rice

## 14.12
 Got comfort version of Everforest color pallete. Also added config for zsh. 
Plugins I use:
```
[ZSH Autosuggestions](https://github.com/zsh-users/zsh-autosuggestions)
[ZSH Syntax Highlighting](https://github.com/zsh-users/zsh-syntax-highlighting)
[ZSH History Substring Search](https://github.com/zsh-users/zsh-history-substring-search)
Git
History
```
And here's my fastfetch config (for "hello world" message in terminal)

## 18.12
 Today's patch is about lf manager. 
Today I customed for myself TUI file manager LF.
Now I use only TUI manager, but we still can call GUI by exec thunar or just thunar

Let's install it

First of all we need LF 
```
sudo pacman -S lf
```
After we need make config dir. 
```
mkdir -p ~/.config/lf
```
Or just copy someone's cfg, as I did
inside we make lfrc file and put here come config (check manual for lf)
Or just yank my folder. here's already icons+preview script. Keep in mind, I use Kitty terminal
```
git clone https://github.com/honkingpill/HyprRice.git 
cd HyprRice/
cp .config/lf ~/.config/lf
```
###Now we need all dependencies

From pacman we install
```
sudo pacman -S fzf ffmpegthumbnailer vim udiskie
```
From AUR we install
```
yay -S pistol trashy
```
Fzf is for jumping to directory (more QOL feature for big dirs)
ffmpegthumbnailer is for thumbnails (actually optional) 
pistol is for preview tool
trashy is trashbox from windows. Actually musthave

And now we making dir for trashbox in ~/.local/share/Trash/files
```
mkdir -p ~/.local/share/Trash/files
```
```
lf binds:
up down for navigate;
left for updir;
right for open;
au for unzip like commands;
ae for wine run;
. to show hidden folders;
dd trash;
de empty trash;
u undo trash;
dD is for deleting with -rf (very carefully) 
x - cut
y - copy
p - paste
R - refresh
C - clear selected
SPACE - select files
mf - mkfile (using vi, vim)
md - mkdir
bg - set wallpaper (using swww)
v - reverse selected ( - * - - > * - * * )
CTRL F - jump to file/folder in this dir
g+smth = cd to ...
```
At very end of config lfrc you can add shortcuts for dirs just like map g<1> cd <2>
On 1 you set button (for example, to get in .config I press g and after c, like get-config)
On 2 you set file/dir (for example, ~/.config)


