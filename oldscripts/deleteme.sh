
#export BLAHBLAH="greg"
#for ((i=100;i<=5100;i+=500)); do
#    export PROBLEM_SIZE=$i
#    echo "mymymy$PROBLEM_SIZE"
#    echo $BLAHBLAH
#    #source ./deleteme2.sh & disown
#done

function doprint {
    echo $ME
}

mylist=("VA" "PA")
for ME in ${mylist[@]}; do
    doprint
    if [ $ME == "VAca" ]; then
        echo "EQUAL!"
    else
        echo "UNEQUAL!"
    fi
done