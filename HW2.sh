#!/usr/local/bin/bash

usage(){
        echo -n -e "\nUsage: sahw2.sh {--sha256 hashes ... | --md5 hashes ...} -i files ...\n\n--sha256: SHA256 hashes to validate input files.\n--md5: MD5 hashes to validate input files.\n-i: Input files.\n"
}

adduser_JSON(){
        for i in $(seq 0 $(($(cat $1 | jq length) - 1)))
        do
                user=$(cat $1 | jq -r ".[$i]")
                username=$(echo $user | jq -r ".username")
                password=$(echo $user | jq -r ".password")
                shell=$(echo $user | jq -r ".shell")
                groups=$(echo $user | jq -r ".groups")
                if `id $username &>/dev/null`; then
                        echo -n -e "Warning: user $username already exists.\n"
                        continue
                fi
                pw useradd -n $username -s $shell
                echo $password | pw usermod $username -h 0
                if [[ $(echo $groups | jq length) == 0 ]]; then
                        continue
                fi
                group_list=""
                for j in $(seq 0 $(($(echo $groups | jq length) - 1)))
                do
                        group=$(echo $groups | jq -r ".[$j]")
                        group_list=`echo $group_list,$group`
                        if ! `getent group $group &>/dev/null`; then
                                pw groupadd $group
                        fi
                done
                group_list="${group_list:1}"
                pw usermod -n $username -G $group_list
        done
}

adduser_CSV(){
        tail -n +2 $1 | while read line; do
                username=$(echo $line | cut -d ',' -f1)
                password=$(echo $line | cut -d ',' -f2)
                shell=$(echo $line | cut -d ',' -f3)
                groups=$(echo $line | cut -d ',' -f4)
                groups=($groups)
                if `id $username &>/dev/null`; then
                        echo -n -e "Warning: user $username already exists.\n"
                        continue
                fi
                pw useradd -n $username -s $shell
                echo $password | pw usermod $username -h 0
                if [[ ${#groups[@]} == 0 ]]; then
                        continue
                fi
                group_list=""
                for group in "${groups[@]}"
                do
                        group_list=`echo $group_list,$group`
                        if ! `getent group $group &>/dev/null`; then
                                pw groupadd $group
                        fi
                done
                group_list="${group_list:1}"
                pw usermod -n $username -G $group_list
        done
}


ERROR_MESSAGE_ARGS="Error: Invalid arguments."
ERROR_MESSAGE_HASH="Error: Only one type of hash function is allowed."
ERROR_MESSAGE_MISMATCH="Error: Invalid values."
ERROR_MESSAGE_CHECKSUM="Error: Invalid checksum."
ERROR_MESSAGE_FORMAT="Error: Invalid file format."

#help
if [ "$1" == '-h' ]; then
        usage
        exit 0
fi;

#detect invalid arguments error (exit code -1)
flag=0 #0b000
i=0

for arg in $@
do
        if [ ${arg:0:1} == '-' ]; then
                case $arg in
                        '--sha256')
                                flag=$((flag | 1)) #0b001
                                param_hash_index=$i
                        ;;
                        '--md5')
                                flag=$((flag | 2)) #0b010
                                param_hash_index=$i
                        ;;
                        '-i')
                                flag=$((flag | 4)) #0b100
                                param_i_index=$i
                        ;;
                        *)
                                echo -n -e $ERROR_MESSAGE_ARGS 1>&2
                                usage
                                exit -1
                esac
        fi
        i=$(($i + 1))
done


if [ $((flag & 4)) -ne 4 -o $((flag & 3)) -eq 0 ]; then
        echo -n -e $ERROR_MESSAGE_ARGS 1>&2
        usage
        exit -1
fi

#detect multiple type of hash function error (exit code -2)
if [ $flag -eq 7 ]; then
        echo -n -e $ERROR_MESSAGE_HASH 1>&2
        exit -2
fi

#detect mismatched file size error (exit code -3)
if [ $(($param_i_index - $param_hash_index - 1)) -ne $(($# - $param_i_index - 1)) -a $(($param_hash_index - $param_i_index - 1)) -ne $(($# - $param_hash_index - 1)) ]; then
        echo -n -e $ERROR_MESSAGE_MISMATCH 1>&2
        exit -3
fi



#validate hash of files
file_num=$((param_i_index - $param_hash_index))
file_num=${file_num#-}
file_num=$((file_num - 1))
hashes=("${@:$((param_hash_index + 2)):$file_num}")
filenames=("${@:$((param_i_index + 2)):$file_num}")
[ $((flag & 1)) -eq 1 ] && hash_method='sha256sum' || hash_method='md5sum'

for n in ${!hashes[@]}
do
        if [ `$hash_method ${filenames[n]} | awk '{ print $1 }'` != ${hashes[n]} ]; then
                echo -n -e $ERROR_MESSAGE_CHECKSUM 1>&2
                exit -4
        fi
done

#detect invalid file format error (exit code -5)
file_format=()
for n in ${!filenames[@]}
do
        file_format+=(-1)
        file_description=`file ${filenames[n]}`
        [[ $file_description == *"JSON data"* ]] && file_format[$n]=0
        [[ $file_description == *"CSV text"* ]] && file_format[$n]=1
        if [[ ${file_format[$n]} -eq -1 ]]; then
                echo -n -e $ERROR_MESSAGE_FORMAT 1>&2
                exit -5
        fi
done

#parse JSON CSV file
if [[ ${#filenames[@]} > 0 ]]; then
        echo -n "This script will create the following user(s): "

        for n in ${!filenames[@]}
        do
                case ${file_format[n]} in
                        0)
                                userlist=`cat ${filenames[n]} | jq -r '.[].username' | tr '\n' ' ' | sed 's/ $//'`
                        ;;
                        1)
                                userlist=`cat ${filenames[n]} | awk -F ',' 'NR > 1 {print $1}' | tr '\n' ' ' | sed 's/ $//'`
                        ;;
                esac
                echo -n "$userlist "
        done
        echo -n "Do you want to continue? [y/n]:"
        read yn
        if [[ $yn == "n" ]] || [[ $yn == "" ]]; then
                exit 0
        fi
else
        exit 0
fi

#create groups & add user with JSON CSV file
for n in ${!filenames[@]}
do
        case ${file_format[n]} in
                0)
                        adduser_JSON ${filenames[n]}
                ;;
                1)
                        adduser_CSV ${filenames[n]}
                ;;
        esac
done
