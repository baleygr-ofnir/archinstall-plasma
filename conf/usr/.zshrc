#            _
#    _______| |__  _ __ ___
#   |_  / __| '_ \| '__/ __|
#  _ / /\__ \ | | | | | (__
# (_)___|___/_| |_|_|  \___|
#
# -----------------------------------------------------
# Load modular configarion
# -----------------------------------------------------
if [ -d ~/.config/zshrc ]; then
    for f in ~/.config/zshrc/*; do
        if [ ! -d $f ]; then
            c=`echo $f | sed -e "s=.config/zshrc=.config/zshrc/custom="`
            [[ -f $c ]] && source $c || source $f
        fi
    done
fi

# -----------------------------------------------------
# Load single customization file (if exists)
# -----------------------------------------------------

if [ -f ~/.zshrc_custom ]; then
    source ~/.zshrc_custom
fi
