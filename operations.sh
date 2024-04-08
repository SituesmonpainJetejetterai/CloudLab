#!/bin/sh

# Define the functions
s_function() {
    printf "%s\n\n" "You called the -s flag. This flag is used to set the variables TF_LOG and TF_LOG_PATH. TF_LOG will be set to TRACE. TF_LOG_PATH will be set to $(pwd)"
    export TF_LOG="TRACE"
    export TF_LOG_PATH=""
}

d_function() {
    printf "You called the -d flag. This flag is used to run 'terraform destroy'.\n"
    terraform state pull
    terraform destroy
}

a_function() {
    printf "You called the -a flag. This flag is used to run 'terraform apply'.\n"
    terraform apply
}

p_function() {
    printf "You called the -p flag. This flag is used to run 'terraform plan'.\n"
    terraform plan
}

D_function() {
    printf "You called the -D flag. This flag is used to run 'terraform destroy -auto-approve'.\n"
    terraform state pull
    terraform destroy -auto-approve
}

A_function() {
    printf "You called the -A flag. This flag is used to run 'terraform apply -auto-approve'.\n"
    terraform apply -auto-approve
}

h_function() {
    printf "Help Information:\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n" "-s: Set a variable" "-d: Run 'terraform destroy'" "-D: Run 'terraform destroy -auto-approve'" "-a: Run 'terraform apply'" "-A: Run 'terraform apply -auto-approve'" "-p: Run 'terraform plan'" "-h: Display this help information"
}

# Check if exactly one argument was passed
# $# is a special variable in shell that holds the number of positional parameters.
if [ $# -ne 1 ]
then
    h_function
    exit 1
fi

# Parse the flags
# getopts is a utility to parse flags
# $@ is a special variable in shell that holds all positional parameters as a list of words
while getopts sdapADh flag
do
    case "${flag}" in
        *s) s_function;;
        d) d_function;;
        D) D_function;;
        a) a_function;;
        A) A_function;;
        p) p_function;;
        h) h_function;;
        *) printf "Invalid flag. Use -h for help.\n"; exit 1;;
    esac
done
