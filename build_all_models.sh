#!/bin/bash

## 20250120  script bash by Lululla for make images
## Modified to support batch building of 131 models
# # ./build_all_models.sh compare
# ===== CONFIG =====
BUILD_VERSION="08"  # <-- SET BUILD VERSION HERE
BUILD_NAME="corvoboys"

export PSEUDO_DISABLED=1
export PSEUDO_UNLOAD=1


export BB_SRCREV_POLICY=cache
export BB_FETCH_PREMIRRORONLY=1
export BB_NO_NETWORK=1 

export GIT_CONFIG_COUNT=4
export GIT_CONFIG_KEY_0=http.postBuffer
export GIT_CONFIG_VALUE_0=524288000
export GIT_CONFIG_KEY_1=http.lowSpeedLimit
export GIT_CONFIG_VALUE_1=0
export GIT_CONFIG_KEY_2=core.compression
export GIT_CONFIG_VALUE_2=0
export GIT_CONFIG_KEY_3=core.fsyncObjectFiles
export GIT_CONFIG_VALUE_3=0
export GIT_SSL_NO_VERIFY=1


GITHUB_IP=$(dig +short github.com | head -1)
if [ -n "$GITHUB_IP" ]; then
    sudo sed -i '/github.com/d' /etc/hosts
    echo "$GITHUB_IP github.com" | sudo tee -a /etc/hosts
else
    echo "Impossibile risolvere github.com, uso IP fisso 140.82.121.4"
    sudo sed -i '/github.com/d' /etc/hosts
    echo "140.82.121.4 github.com" | sudo tee -a /etc/hosts
fi



# Se l'argomento è "compare", esegue solo il confronto modelli ed esce
if [ "$1" = "compare" ]; then
    # Crea lista modelli supportati dal codice
    find meta-* -name "*.conf" -path "*/conf/machine/*" -exec basename {} .conf \; | sort > /tmp/current.txt

    # Estrai TUTTI i modelli da build_all_models.sh (in modo affidabile)
    source build_all_models.sh 2>/dev/null
    for array in ${!MODELS_*}; do
        eval "values=(\"\${$array[@]}\")"
        printf '%s\n' "${values[@]}"
    done | sort -u > /tmp/miei.txt

    # Confronto
    echo "❌ DA RIMUOVERE (modelli nel tuo script ma non supportati):"
    comm -13 /tmp/current.txt /tmp/miei.txt
    echo -e "\n✅ DA AGGIUNGERE (modelli supportati ma non nel tuo script):"
    comm -23 /tmp/current.txt /tmp/miei.txt
    exit 0
fi

# ==========================
# Check required tools
check_tools() {
    local tools="chrpath lz4c pzstd unzstd zstd java svn"
    local missing=""
    for t in $tools; do
        if ! command -v $t >/dev/null 2>&1; then
            missing="$missing $t"
        fi
    done
    if [ -n "$missing" ]; then
        print_message "error" "Missing Tools: $missing"
        echo "Install: sudo apt-get install -y chrpath lz4 zstd default-jre subversion"
        return 1
    fi
    return 0
}

# Call control at the beginning of the script
if ! check_tools; then
    exit 1
fi

# Function to show messages with custom colors
function print_message {
    local msg_type=$1
    local msg=$2
    case $msg_type in
        "info") echo -e "\033[1;34m[INFO] $msg\033[0m" ;;  # Blue
        "error") echo -e "\033[1;31m[ERROR] $msg\033[0m" ;;  # Red
        "success") echo -e "\033[1;32m[SUCCESS] $msg\033[0m" ;;  # Green
        *) echo "$msg" ;;
    esac
}

# Function progress bar
function progress_bar {
    local total=$1
    local current=0
    while [ $current -le $total ]; do
        let "progress=($current*100)/$total"
        echo -n "#"
        sleep 0.1
        let "current++"
    done
    echo
}

# Init Cleaning
rm -f build/bitbake.lock build/bitbake.sock
print_message "info" "Initializing cleaning..."

# Producers and models
declare -A PRODUCERS=(
    [0]="Abcom"
    [1]="Amiko"
    [2]="Axas"
    [3]="Dream"
    [4]="Edision"
    [5]="Formuler"
    [6]="Gfutures"
    [7]="Gi"
    [8]="Gigablue"
    [9]="Maxytec"
    [10]="Miraclebox"
    [11]="Octagon"
    [12]="Qviart"
    [13]="Sab"
    [14]="Spycat"
    [15]="Uclan"
    [16]="Vuplus"
    [17]="Xp"
    [18]="Xpeedc"
    [19]="Xsarius"
    [20]="Xtrend"
    [21]="Zgemma"
)

Models for each manufacturer
declare -A MODELS_Abcom=([0]="pulse4k" [1]="pulse4kmini")
declare -A MODELS_Amiko=([0]="vipercombo" [1]="vipercombohdd" [2]="viperslim" [3]="vipert2c")
declare -A MODELS_Axas=([0]="e4hd")
declare -A MODELS_Dream=([0]="dm8000")  #  [1]="dm500hd" [2]="dm500hdv2" [3]="dm800se" [4]="dm800sev2" [5]="dm520" [6]="dm820" [7]="dm7020hd" [8]="dm7020hdv2" [9]="dm7080" [10]="dm900" [11]="dm920" [12]="dreamone" [13]="dreamtwo")
declare -A MODELS_Edision=([0]="osmega" [1]="osmini" [2]="osmini4k" [3]="osminiplus" [4]="osmio4k" [5]="osmio4kplus" [6]="osnino" [7]="osninoplus" [8]="osninopro")
declare -A MODELS_Formuler=([0]="formuler1" [1]="formuler3" [2]="formuler4" [3]="formuler4turbo")
declare -A MODELS_Gfutures=([0]="bre2ze4k" [1]="hd11" [2]="hd51" [3]="hd60" [4]="hd61" [5]="hd66se" [6]="hd500c" [7]="hd530c" [8]="hd1100" [9]="hd1200" [10]="hd1265" [11]="hd1500" [12]="hd2400" [13]="vs1000" [14]="vs1500")
declare -A MODELS_Gi=([0]="et1x000" [1]="et7000mini")
declare -A MODELS_Gigablue=([0]="gbquad4k" [1]="gbquad4kpro" [2]="gbtrio4k" [3]="gbue4k")
declare -A MODELS_Maxytec=([0]="multibox" [1]="multiboxpro" [2]="multiboxse")
declare -A MODELS_Miraclebox=([0]="mbmicro" [1]="mbmicrov2" [2]="mbtwinplus")
declare -A MODELS_Octagon=([0]="sfx6008" [1]="sf8008" [2]="sf8008m" [3]="sx88v2")
declare -A MODELS_Qviart=([0]="dual" [1]="lunix" [2]="lunix3-4k" [3]="lunix4k")
declare -A MODELS_Sab=([0]="alphatriplehd")
declare -A MODELS_Spycat=([0]="spycatmini" [1]="spycat" [2]="spycatminiplus")
declare -A MODELS_Uclan=([0]="ustym4kpro" [1]="ustym4ks2ottx")
declare -A MODELS_Vuplus=([0]="vuduo" [1]="vuduo2" [2]="vuduo4k" [3]="vuduo4kse" [4]="vusolo" [5]="vusolo2" [6]="vusolo4k" [7]="vusolose" [8]="vuultimo" [9]="vuultimo4k" [10]="vuuno" [11]="vuuno4k" [12]="vuuno4kse" [13]="vuzero" [14]="vuzero4k")
declare -A MODELS_Xp=([0]="xp1000")
declare -A MODELS_Xpeedc=([0]="xpeedc")
declare -A MODELS_Xsarius=([0]="fusionhd" [1]="fusionhdse" [2]="galaxy4k" [3]="purehd" [4]="purehdse" [5]="revo4k")
declare -A MODELS_Xtrend=([0]="et4x00" [1]="et5x00" [2]="et6x00" [3]="et7x00" [4]="et9x00" [5]="et8000" [6]="et8500" [7]="et10000")
declare -A MODELS_Zgemma=([0]="sh1" [1]="h3" [2]="h4" [3]="h5" [4]="h6" [5]="h7" [6]="h8" [7]="h9" [8]="h9combo" [9]="h9combose" [10]="h9se" [11]="h10" [13]="h11" [14]="h17" [15]="h17twin" [16]="hzero" [17]="i55" [18]="i55plus" [19]="i55se" [20]="lc")


# Build all models function
function build_all_models {
    local build_option=$1
    local total_models=0
    local current_model=0
    
    # Count total models
    for producer_index in "${!PRODUCERS[@]}"; do
        producer_name="${PRODUCERS[$producer_index]}"
        array_name="MODELS_$producer_name"
        declare -n model_array=$array_name
        total_models=$((total_models + ${#model_array[@]}))
    done

    print_message "info" "Starting batch build for $total_models models..."
    print_message "info" "Build version: $BUILD_NAME-$BUILD_VERSION"
    
    # Main build loop
    # Carica ambiente build
    cd build 2>/dev/null || { print_message "error" "Build directory not found"; return 1; }
    source env.source
    export LANG=C
    cd ..
    for producer_index in "${!PRODUCERS[@]}"; do
        producer_name="${PRODUCERS[$producer_index]}"
        array_name="MODELS_$producer_name"
        declare -n model_array=$array_name
        
        for model_index in "${!model_array[@]}"; do
            current_model=$((current_model + 1))
            model_name="${model_array[$model_index]}"
            
            print_message "info" "Building [$current_model/$total_models] ${producer_name} ${model_name}..."
            
            # Execute build command
            if MACHINE="$model_name" make "$build_option"; then
                print_message "success" "Build succeeded for ${model_name}"
            else
                print_message "error" "Build FAILED for ${model_name}, continuing..."
            fi
            # Show progress
            echo -n "Progress: "
            progress_bar $total_models $current_model
        done
    done
    
    print_message "success" "Batch build completed! $current_model/$total_models models processed"
}

# Batch build options
batch_option=$(dialog --stdout --clear --backtitle "Batch Build System" \
    --menu "Select build option:" 15 50 4 \
    1 "Build Single Model" \
    2 "Build All Models (Image)" \
    3 "Build All Models (Feed)" \
    4 "Exit")

[ -z "$batch_option" ] && clear && exit 1

case $batch_option in
    1)  # Single model build (original flow)
        sorted_producers=($(for p in "${!PRODUCERS[@]}"; do echo "$p ${PRODUCERS[$p]}"; done | sort -k2 | cut -d ' ' -f 1))
        list=()
        for i in "${!sorted_producers[@]}"; do
            list+=("$i" "${PRODUCERS[$i]}")
        done
        
        producer=$(dialog --stdout --clear --backtitle "Model Selection" --menu "Select Producer" 40 50 40 "${list[@]}")
        [ -z "$producer" ] && clear && exit
        
        case ${PRODUCERS[$producer]} in
            "Abcom") models=("${MODELS_Abcom[@]}") ;;
            "Amiko") models=("${MODELS_Amiko[@]}") ;;
            "Axas") models=("${MODELS_Axas[@]}") ;;
            "Dream") models=("${MODELS_Dream[@]}") ;;
            "Edision") models=("${MODELS_Edision[@]}") ;;
            "Formuler") models=("${MODELS_Formuler[@]}") ;;
            "Gfutures") models=("${MODELS_Gfutures[@]}") ;;
            "Gi") models=("${MODELS_Gi[@]}") ;;
            "Gigablue") models=("${MODELS_Gigablue[@]}") ;;
            "Maxytec") models=("${MODELS_Maxytec[@]}") ;;
            "Miraclebox") models=("${MODELS_Miraclebox[@]}") ;;
            "Octagon") models=("${MODELS_Octagon[@]}") ;;
            "Qviart") models=("${MODELS_Qviart[@]}") ;;
            "Sab") models=("${MODELS_Sab[@]}") ;;
            "Spycat") models=("${MODELS_Spycat[@]}") ;;
            "Uclan") models=("${MODELS_Uclan[@]}") ;;
            "Vuplus") models=("${MODELS_Vuplus[@]}") ;;
            "Xp") models=("${MODELS_Xp[@]}") ;;
            "Xpeedc") models=("${MODELS_Xpeedc[@]}") ;;
            "Xsarius") models=("${MODELS_Xsarius[@]}") ;;
            "Xtrend") models=("${MODELS_Xtrend[@]}") ;;
            "Zgemma") models=("${MODELS_Zgemma[@]}") ;;
            *) clear && exit ;;
        esac

        sorted_models=($(for m in "${!models[@]}"; do echo "$m ${models[$m]}"; done | sort -k2 | cut -d ' ' -f 1))
        list=()
        for i in "${!sorted_models[@]}"; do
            list+=("$i" "${models[$i]}")
        done
        
        model=$(dialog --stdout --clear --menu "Select Model ${PRODUCERS[$producer]}" 40 50 40 "${list[@]}")
        [ -z "$model" ] && clear && exit
        
        selected_model=${models[$model]}
        build_option=$(dialog --stdout --clear --menu "Select Build Type" 40 50 2 \
            "image" "Image" \
            "feed" "Feed")
        [ -z "$build_option" ] && clear && exit
        
        print_message "info" "Building ${PRODUCERS[$producer]} $selected_model..."
        print_message "info" "Build version: $BUILD_NAME-$BUILD_VERSION"
        
        # Esegui il build
        if MACHINE="$selected_model" make "$build_option"; then
            print_message "success" "Build completed successfully!"
            
        else
            print_message "error" "Build FAILED for $selected_model!"
            exit 1
        fi
        ;;

    2)  # Build all models (Image)
        # make update  # Commented: Causes SSH problems
        build_all_models "image"
        ;;
        
    3)  # Build all models (Feed)
        # make update  # Commented: Causes SSH problems
        build_all_models "feed"
        ;;
        
    4)  # Exit
        clear
        exit 0
        ;;
esac

exit 0
