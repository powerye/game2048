#!/bin/bash

trap 'echo quit >&3' INT TERM QUIT

declare -A cell
startx=1
starty=1
score=0

##########YOUR CONFIG##########
WIDTH=4
#any Integer
AI=NO
#YES or NO
DEPTH=1
#It works when AI=YES
BESTSCORE=4868
#Modifying BESTSCORE is not recommended
##########OVER CONFIG##########

drawcell() {
    local num

    echo -en "[0m"
    case $3 in
    ' ')  echo -en "[$2;${1}H[0m    ";;
    2)    echo -en "[$2;${1}H[0m   2";;
    4)    echo -en "[$2;${1}H[0m   4";;
    8)    echo -en "[$2;${1}H[0m   8";;
    16)   echo -en "[$2;${1}H[35m  16";;
    32)   echo -en "[$2;${1}H[35m  32";;
    64)   echo -en "[$2;${1}H[35m  64";;
    128)  echo -en "[$2;${1}H[36m 128";;
    256)  echo -en "[$2;${1}H[34m 256";;
    512)  echo -en "[$2;${1}H[32m 512";;
    1024) echo -en "[$2;${1}H[31m1024";;
    2048) echo -en "[$2;${1}H[33m2048";;
    4096) echo -en "[$2;${1}H[43;31m4096";;
    8192) echo -en "[$2;${1}H[41;30m8192";;
    *)    num=`echo "l($3)/l(2)" | bc -l`
          num="2^${num%%.*}"
          num="${num::4}"
          echo -en "[$2;${1}H[44;31m$num";;
    esac
}

#drawboard() {
#    clear
#
#    echo '╔════╤════╤════╤════╗'
#    echo '║    │    │    │    ║'
#    echo '╟────┼────┼────┼────╢'
#    echo '║    │    │    │    ║'
#    echo '╟────┼────┼────┼────╢'
#    echo '║    │    │    │    ║'
#    echo '╟────┼────┼────┼────╢'
#    echo '║    │    │    │    ║'
#    echo '╚════╧════╧════╧════╝'
#    echo -en "[10;2Hscore: $score"
#    echo -en "[11;2Hbestscore: $BESTSCORE"
#}

drawboard() {
    local i j
    local overx=$[startx+WIDTH*5]
    local overy=$[starty+WIDTH*2]
    echo -en "[0m"

    for i in `seq $WIDTH`
    do  for j in `seq $WIDTH`
        do  echo -en "[$[starty+2*j-2];$[startx+5*i-5]H┼────"
            echo -en "[$[starty+2*j-1];$[startx+5*i-5]H│"
        done
    done

    for i in `seq $WIDTH`
    do  echo -en "[$starty;$[startx+i*5-5]H╤════"
        echo -en "[$overy;$[startx+i*5-5]H╧════"
    done

    for i in `seq $WIDTH`
    do  echo -en "[$[starty+i*2-2];${startx}H╟"
        echo -en "[$[starty+i*2-1];${startx}H║"
        echo -en "[$[starty+i*2-2];${overx}H╢"
        echo -en "[$[starty+i*2-1];${overx}H║"
    done


    echo -en "[$starty;${startx}H╔"
    echo -en "[$starty;${overx}H╗"
    echo -en "[$overy;${startx}H╚"
    echo -en "[$overy;${overx}H╝"
    echo -en "[$[overy+1];$[startx+1]Hscore: $score[K"
    echo -en "[$[overy+2];$[startx+1]Hbestscore: $BESTSCORE"
}

drawhelp() {
    local helpx=$[WIDTH*5+startx+2]
    local helpy=$starty

    echo -en "[$[helpy+1];${helpx}HArrow keys or w,a,s,d control direction"
    echo -en "[$[helpy+2];${helpx}Hq Qiut"
    echo -en "[$[helpy+3];${helpx}Hr Autorun the game"
    echo -en "[$[helpy+4];${helpx}Hn Stop autorun"
    echo -en "[$[helpy+5];${helpx}Hh Hint"
}

gameinit() {
    local i j pos

    : ${WIDTH:=4}
    : ${AI:=NO}
    : ${BESTSCORE:=0}
    [ $WIDTH -lt 2 ] && { echo "WIDTH is too small!"; exit; }
    which shuf sed grep bc seq &> /dev/null || { echo "Sorry,I need command bc seq grep sed."; exit; }
    for i in `seq $[WIDTH*2+3]`
    do  echo
    done
    eval echo -e '['$[WIDTH*2+4]'A'

    echo -en "[?25l"
    echo -en "[6n"
    read -sdR pos
    pos=`echo $pos | sed 's/.*\[\(.*\)/\1/'`
    startx=${pos##*;}
    starty=${pos%%;*}

    pipe=`mktemp -u /tmp/key2048XXXXXX`
    mkfifo $pipe
    exec 3<>$pipe
    rm -f $pipe

    for i in `seq 0 $[WIDTH-1]`
    do  for j in `seq 0 $[WIDTH-1]`
        do  cell[$i,$j]='empty'
        done
    done

    drawboard
    drawhelp
    setcell
    setcell
    refresh
}

setcell() {
    local x y

    while [ ! $3 ]
    do  x=$[RANDOM%WIDTH]
        y=$[RANDOM%WIDTH]
        [ ${cell[$x,$y]} == 'empty' ] && { let cell[$x,$y]=RANDOM%10?2:4; return; }
    done

    cell[$1,$2]=$3
}

gameover() {
    [ $score -gt $BESTSCORE ] &&  sed -i "/^##########Y/,/^##########O/s/^\(BESTSCORE=\).*/\1$score/" $0
    echo -en "[?25h[$[WIDTH*2+3+starty];0H[0m"
    kill -9 0
}

tryagain() {
    local i

    echo -en "[31m"
    echo -en "[$[starty+2];$[startx+5]H┌───────────┐"
    echo -en "[$[starty+3];$[startx+5]H│GAMEOVER!  │"
    echo -en "[$[starty+4];$[startx+5]H│t:try again│"
    echo -en "[$[starty+5];$[startx+5]H│q:quit     │"
    echo -en "[$[starty+6];$[startx+5]H└───────────┘"

    read <&3
    [ "$REPLY" == 'continue' ] && {
        [ $score -gt $BESTSCORE ] &&  sed -i "/^##########Y/,/^##########O/s/^\(BESTSCORE=\).*/\1$score/" $0
        BESTSCORE=$score
        score=0
        for i in ${!cell[@]}
        do  cell[$i]='empty'
        done
        drawboard
        setcell
        setcell
        refresh
        gamestart
    } || gameover
}

refresh() {
    local i j

    for i in `seq 0 $[WIDTH-1]`
    do  for j in `seq 0 $[WIDTH-1]`
        do  if [ ${cell[$i,$j]} == 'empty' ]
            then    drawcell $[startx+i*5+1] $[starty+j*2+1] ' '
            else    drawcell $[i*5+1+startx] $[j*2+1+starty] ${cell[$i,$j]}
            fi
        done
    done
    echo -en "[$[starty+WIDTH*2+1];$[startx+1]H[0mscore: $score"
}

move() {
    local f1 f2 f3 f4 f5 f6 i j tmp
    local line=()
    case $1 in
    "up")
        f1='i=0';f2='i<=WIDTH-1';f3='i++'
        f4='j=0';f5='j<=WIDTH-1';f6='j++';;
    "down")
        f1='i=0';f2='i<=WIDTH-1';f3='i++'
        f4='j=WIDTH-1';f5='j>=0';f6='j--';;
    "left")
        f1='j=0';f2='j<=WIDTH-1';f3='j++'
        f4='i=0';f5='i<=WIDTH-1';f6='i++';;
    "right")
        f1='j=0';f2='j<=WIDTH-1';f3='j++'
        f4='i=WIDTH-1';f5='i>=0';f6='i--';;
    *)  return
    esac

    for(($f1;$f2;$f3))
    do  line=()
        for(($f4;$f5;$f6))
        do  [ ${cell[$i,$j]} != 'empty' ] && line+=(${cell[$i,$j]})
        done
        for tmp in `seq 0 $[WIDTH-2]`
        do  [ ${line[tmp]} ] || continue
            if [ ${line[tmp]} == "${line[tmp+1]}" ]
            then    ((line[tmp]*=2))
                    ((score+=line[tmp]))
                    line[tmp+1]=""
            fi
        done
        line=(${line[@]})
        for tmp in `seq $WIDTH`; do  line+=('empty'); done
        line=`echo ${line[@]} | tr ' ' '\n'`
        for(($f4;$f5;$f6))
        do  read cell[$i,$j]
        done <<< "$line"
    done
}

#foolishAI() {
#    local AIcell AIscore i
#    local max=0
#    local maxarrow
#    declare -A AIcell
#
#    for i in ${!cell[@]}
#    do  AIcell[$i]=${cell[$i]}
#    done
#    AIscore=$score
#
#    haveAtry test &> /dev/null ||
#    haveAtry() {
#        [ $1 == "test" ] && return 0
#        move $1
#        [ $score -ge $max ] && { max=$score; maxarrow=$1; }
#        for i in ${!cell[@]}
#        do  cell[$i]=${AIcell[$i]}
#        done
#        score=$AIscore
#    }
#    
#    for i in `shuf -e up down left right`
#    do  haveAtry $i
#    done
#
#    echo $maxarrow
#}

ab() {
    local depth=$1
    local a=$2
    local b=$3
    local whosturn=$4
    local i j k l t arrow
    local cellcopy scorecopy
    declare -A cellcopy

    [ $depth -le 0 ] && { echo $score; return; }
    for i in ${!cell[@]}
    do  cellcopy[$i]=${cell[$i]}
    done
    scorecopy=$score

    if [ $whosturn == 'computer' ]
    then    for i in up down right left
            do  move $i
                t=`ab $[depth-1] $a $b randset`
                [ $t -gt $a ] && {
                    [ $t -gt $b ] && { echo $t; return; }
                    a=$t
                }
                for j in ${!cell[@]}
                do  cell[$j]=${cellcopy[$j]}
                done
                score=$scorecopy
            done
            echo $a
            return
    elif [ $whosturn == 'first' ]
    then    for i in `shuf -e up down right left`
            do  move $i
                t=`ab $[depth-1] $a $b randset`
                [ $t -gt $a ] && { a=$t; arrow=$i; }
                for j in ${!cell[@]}
                do  cell[$j]=${cellcopy[$j]}
                done
                score=$scorecopy
            done
            echo $arrow
            return
    else    for i in `seq 0 $[WIDTH-1]`
            do  for j in `seq 0 $[WIDTH-1]`
                do  [ ${cell[$i,$j]} == 'empty' ] && {
                        for k in 2 4
                        do  setcell $i $j $k
                            t=`ab $[depth-1] $a $b computer`
                            [ $t -lt $b ] && {
                                [ $t -lt $a ] && { echo $t; return; }
                                b=$t
                            }
                            for l in ${!cell[@]}
                            do  cell[$l]=${cellcopy[$l]}
                            done
                            score=$scorecopy
                        done
                    }
                done
            done
            echo $b
            return
    fi
}

foolishAI() {
    local AIanswer
    if [ $DEPTH -gt 0 ]
    then    AIanswer=`ab $DEPTH 0 2147483647 first`
    else    AIanswer=`shuf -e up down right left | sed -n '1p'`
    fi
    echo $AIanswer
}

gamestart() {
    local oldcell i j
    declare -A oldcell
    local over2048='notyet'
    local count=0

    while :
    do  [[ $AI =~ [Yy] ]] && foolishAI >&3
        read <&3
        
        for i in ${!cell[@]}
        do  oldcell[$i]=${cell[$i]}
        done

        case $REPLY in
        up|down|left|right) move $REPLY;;
        autorun)            AI=YES;continue;;
        noauto)             AI=NO;continue;;
        hint)               move `foolishAI`;;
        quit)               gameover;;
        *)                  continue
        esac

        for i in ${!cell[@]}
        do  [ ${oldcell[$i]} != ${cell[$i]} ] && { setcell; refresh; break; }
            ((count++))
        done

        [ $count -eq $[WIDTH*WIDTH] ] && continue
        count=0
        [ $[RANDOM%9] -eq $[RANDOM%9] ] && drawboard

        [ $over2048 ] && {
            for i in ${cell[@]}
            do  [ "$i" == 2048 ] && {
                    echo -en "[34m"
                    echo -en "[$[starty+2];$[startx+5]H┌────────────────┐"
                    echo -en "[$[starty+3];$[startx+5]H│Congratulations!│"
                    echo -en "[$[starty+4];$[startx+5]H│t:continue      │"
                    echo -en "[$[starty+5];$[startx+5]H│q:quit          │"
                    echo -en "[$[starty+6];$[startx+5]H└────────────────┘"
                    read <&3
                    [ "$REPLY" == 'continue' ] && {
                        unset over2048
                        drawboard
                        refresh
                    } || gameover
                }
            done
        }

        for i in `seq 0 $[WIDTH-1]`
        do  for j in `seq 0 $[WIDTH-1]`
            do  [ ${cell[$i,$j]} == 'empty' ] || [ ${cell[$i,$j]} == "${cell[$[i+1],$j]}" ] || [ ${cell[$i,$j]} == "${cell[$i,$[j+1]]}" ] && continue 3
            done
        done

        tryagain
    done
}

keypress() {
    local key

    while read -s -n1 key
    do  grep -qv [ABCDwasdqQrRnNhHTt] <<< $key && continue
        case $key in
        [Aw]) echo up;;
        [Bs]) echo down;;
        [Cd]) echo right;;
        [Da]) echo left;;
        [Rr]) echo autorun;;
        [Nn]) echo noauto;;
        [Hh]) echo hint;;
        [Qq]) echo quit;;
        [Tt]) echo continue;;
        *)    continue
        esac
    done >&3
}

gameinit
gamestart &
keypress
