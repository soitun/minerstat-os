#!/bin/bash
#exec 2>/dev/null

if [ ! $1 ]; then
  echo ""
  echo "--- EXAMPLE ---"
  echo "./overclock_amd.sh 1 2 3 4 5 6 7"
  echo "1 = GPUID"
  echo "2 = Memory Clock"
  echo "3 = Core Clock"
  echo "4 = Fan Speed"
  echo "5 = VDDC"
  echo "6 = VDDCI"
  echo "7 = MVDD"
  echo ""
  echo "-- Full Example --"
  echo "./overclock_amd.sh 0 2100 1140 80 850 900 1000"
  echo ""
fi

if [ $1 ]; then

  #################################£
  # Declare
  GPUID=$1
  MEMCLOCK=$2
  CORECLOCK=$3
  FANSPEED=$4
  VDDC=$5
  VDDCI=$6
  MVDD=$7
  # GPU BUS ID TO INT
  GPUBUS=$8
  if [ ! -z $GPUBUS ]; then
    GPUBUSINT=$(echo $GPUBUS | cut -f 1 -d '.')
    GPUBUS=$(python -c 'print(int("'$GPUBUSINT'", 16))')
  fi
  # instant / normal
  INSTANT=$9
  # core state
  GPUINDEX=${10}

  if [ "$INSTANT" = "instant" ]; then
    echo "INSTANT OVERRIDE"
    echo "BUS => $8"
    if [ -f "/dev/shm/oc_old_$8.txt" ]; then
      echo
      echo "=== COMPARE VALUE FOUND ==="
      sudo cat /dev/shm/oc_old_$8.txt
      MEMCLOCK_OLD=$(cat /dev/shm/oc_old_$8.txt | grep "MEMCLOCK=" | xargs | sed 's/.*=//' | xargs)
      CORECLOCK_OLD=$(cat /dev/shm/oc_old_$8.txt | grep "CORECLOCK=" | xargs | sed 's/.*=//' | xargs)
      FANSPEED_OLD=$(cat /dev/shm/oc_old_$8.txt | grep "FAN=" | xargs | sed 's/.*=//' | xargs)
      VDDC_OLD=$(cat /dev/shm/oc_old_$8.txt | grep "VDDC=" | xargs | sed 's/.*=//' | xargs)
      VDDCI_OLD=$(cat /dev/shm/oc_old_$8.txt | grep "VDDCI=" | xargs | sed 's/.*=//' | xargs)
      MVDD_OLD=$(cat /dev/shm/oc_old_$8.txt | grep "MVDD=" | xargs | sed 's/.*=//' | xargs)
      GPUBUS_OLD=$(cat /dev/shm/oc_old_$8.txt | grep "BUS=" | xargs | sed 's/.*=//' | xargs)
      echo "==========="
      echo
    else
      MEMCLOCK_OLD="skip"
      CORECLOCK_OLD="skip"
      FANSPEED_OLD="skip"
      VDDC_OLD="skip"
      VDDCI_OLD="skip"
      MVDD_OLD="skip"
      GPUBUS_OLD=$(cat /dev/shm/oc_$8.txt | grep "BUS=" | xargs | sed 's/.*=//' | xargs)
    fi
    echo "=== NEW VALUES FOUND ==="
    sudo cat /dev/shm/oc_$8.txt
    MEMCLOCK_NEW=$(cat /dev/shm/oc_$8.txt | grep "MEMCLOCK=" | xargs | sed 's/.*=//' | xargs)
    CORECLOCK_NEW=$(cat /dev/shm/oc_$8.txt | grep "CORECLOCK=" | xargs | sed 's/.*=//' | xargs)
    FANSPEED_NEW=$(cat /dev/shm/oc_$8.txt | grep "FAN=" | xargs | sed 's/.*=//' | xargs)
    VDDC_NEW=$(cat /dev/shm/oc_$8.txt | grep "VDDC=" | xargs | sed 's/.*=//' | xargs)
    VDDCI_NEW=$(cat /dev/shm/oc_$8.txt | grep "VDDCI=" | xargs | sed 's/.*=//' | xargs)
    MVDD_NEW=$(cat /dev/shm/oc_$8.txt | grep "MVDD=" | xargs | sed 's/.*=//' | xargs)
    GPUBUS_NEW=$(cat /dev/shm/oc_$8.txt | grep "BUS=" | xargs | sed 's/.*=//' | xargs)
    echo "==========="
    echo
    echo "=== COMPARE ==="
    ##################
    MEMCLOCK="skip"
    CORECLOCK="skip"
    FANSPEED="skip"
    VDDC="skip"
    VDDCI="skip"
    MVDD="skip"
    BUS=""
    ##################
    if [ "$MEMCLOCK_OLD" != "$MEMCLOCK_NEW" ]; then
      MEMCLOCK=$MEMCLOCK_NEW
    fi
    if [ "$CORECLOCK_OLD" != "$CORECLOCK_NEW" ]; then
      CORECLOCK=$CORECLOCK_NEW
    fi
    if [ "$FANSPEED_OLD" != "$FANSPEED_NEW" ]; then
      FANSPEED=$FANSPEED_NEW
    fi
    if [ "$VDDC_OLD" != "$VDDC_NEW" ]; then
      VDDC=$VDDC_NEW
    fi
    if [ "$VDDCI_OLD" != "$VDDCI_NEW" ]; then
      VDDCI=$VDDCI_NEW
    fi
    if [ "$MVDD_OLD" != "$MVDD_NEW" ]; then
      MVDD=$MVDD_NEW
    fi
    if [ "$GPUBUS_OLD" != "$GPUBUS_NEW" ]; then
      BUS=$GPUBUS_NEW
    fi
  fi

  ## BULIDING QUERIES
  STR1="";
  STR2="";
  STR3="";
  STR4="";
  STR5="";
  STR6="";
  OHGOD1="";
  OHGOD2="";
  OHGOD3="";
  OHGOD4="";
  R9="";

  # Check this is older R, or RX Series

  if [ ! -z $GPUBUS ]; then
    GID=$GPUBUS
    recheckID=$(ls /sys/bus/pci/devices/*$GPUBUSINT":00.0"/drm | grep "card" | sed 's/[^0-9]*//g')
    GPUID=$recheckID
  else
    GID=""
  fi

  isThisR9=$(sudo /home/minerstat/minerstat-os/bin/amdcovc | grep "PCI $GID" | grep "R9"| sed 's/^.*R9/R9/' | cut -f1 -d' ' | sed 's/[^A-Z0-9]*//g')
  isThisVega=$(sudo /home/minerstat/minerstat-os/bin/amdcovc | grep "PCI $GID" | grep "Vega" | sed 's/^.*Vega/Vega/' | sed 's/[^a-zA-Z]*//g')
  isThisVegaII=$(sudo /home/minerstat/minerstat-os/bin/amdcovc | grep "PCI $GID" | grep "Vega" | sed 's/^.*Vega/Vega/' | sed 's/[^a-zA-Z]*//g')
  isThisVegaVII=$(sudo /home/minerstat/minerstat-os/bin/amdcovc | grep "PCI $GID" | grep "VII" | sed 's/^.*VII/VII/' | sed 's/[^a-zA-Z]*//g')
  isThisNavi=$(sudo /home/minerstat/minerstat-os/bin/amdcovc | grep "PCI $GID" | grep -E "5500|5550|5600|5650|5700|5750|5800|5850|5900" | wc -l)

  ##  echo "----"
  ##  echo $GPUBUS
  ##  echo $GPUBUSINT
  ##  echo $GID
  ##  echo $GPUID
  ##  sudo /home/minerstat/minerstat-os/bin/amdcovc | grep "PCI $GID" | grep "VII" | sed 's/^.*VII/VII/' | sed 's/[^a-zA-Z]*//g'
  ##  echo "----"


  ########## NAVI ##################
  if [ "$isThisNavi" -gt "0" ]; then
    echo "--**--**-- NAVI --**--**--"
    echo "Loading NAVI OC Script.."
    sudo ./overclock_navi.sh $GPUID $2 $3 $4 $5 $7 ${10}
    exit 1
  fi
  ################################

  ########## VEGA ##################
  if [ "$isThisVega" = "Vega" ]; then
    echo "--**--**-- VEGA --**--**--"
    echo "Loading VEGA OC Script.."
    sudo ./overclock_vega.sh $GPUID $2 $3 $4 $5 $7 ${10}
    exit 1
  fi
  ################################

  ########## VEGA VII ############
  if [ "$isThisVegaVII" = "VII" ]; then
    echo "--**--**-- VII --**--**--"
    echo "Loading VEGA VII OC Script.."
    sudo ./overclock_vega7.sh $GPUID $2 $3 $4 $5 $7 ${10}
    exit 1
  fi
  ################################

  ########## BACKUP ##################
  if [ "$isThisVegaII" = "VegaFrontierEdition" ]; then
    echo "--**--**-- VEGA FRONTIER --**--**--"
    echo "Loading VEGA OC Script.."
    sudo ./overclock_vega.sh $GPUID $2 $3 $4 $5 $7 ${10}
    exit 1
  fi
  ################################

  if [ "$isThisR9" != "R9" ]; then
    if [ "$FANSPEED" != "skip" ]; then
      if [ "$FANSPEED" != 0 ]; then
        STR1="--set-fanspeed $FANSPEED";
        STR2="fanspeed:$GPUID=$FANSPEED";
      fi
    fi

    # Reset
    sudo bash -c "echo r > /sys/class/drm/card$GPUID/device/pp_od_clk_voltage"

    ## Detect state's
    maxMemState=$(sudo cat /sys/class/drm/card$GPUID/device/pp_dpm_mclk | tac | head -n1 | sed 's/\:.*//' | sed 's/[^0-9]*//g' | xargs)
    maxCoreState=$(sudo cat /sys/class/drm/card$GPUID/device/pp_dpm_sclk | tac | head -n1 | sed 's/\:.*//' | sed 's/[^0-9]*//g' | xargs)
    #currentCoreState=$(sudo su -c "cat /sys/class/drm/card$GPUID/device/pp_dpm_sclk | grep '*' | cut -f1 -d':' | sed -r 's/.*([0-9]+).*/\1/' | sed 's/[^0-9]*//g'")
    #currentMemState=$(sudo su -c "cat /sys/class/drm/card$GPUID/device/pp_dpm_mclk | grep '*' | cut -f1 -d':' | sed -r 's/.*([0-9]+).*/\1/' | sed 's/[^0-9]*//g'")
    currentCoreState="3"
    currentMemState="1"
    currentVDDC=$(sudo su -c "cat /sys/class/drm/card$GPUID/device/pp_od_clk_voltage" | sed '/OD_MCLK/Q' | grep "$currentCoreState:" | awk '{ print $3 }' | sed 's/[^0-9]*//g' | xargs)
    currentMVDD=$(sudo su -c "cat /sys/class/drm/card$GPUID/device/pp_od_clk_voltage" | sed '/OD_MCLK/,$!d' | grep "$currentMemState:" | awk '{ print $3 }' | sed 's/[^0-9]*//g' | xargs)
    #currentCoreState=5

    if [ "$R9" != "" ]; then
      sudo ./amdcovc $R9 | grep "Setting"
    fi

    ## If $currentCoreState equals zero (undefined)
    ## Use maxCoreState BUT IF ZERO means idle use the same

    if [ -z $currentCoreState ]; then
      echo "ERROR: No Current Core State found for GPU$GPUID"
      currentCoreState=3
    fi

    if [ "$currentCoreState" = 0 ]; then
      echo "WARN: GPU$GPUID was idle, using default states (5) (Idle)"
      currentCoreState=3
    fi

    ## Memstate just for protection
    if [ -z $maxMemState ]; then
      echo "ERROR: No Current Mem State found for GPU$GPUID"
      maxMemState=1; # 1 is exist on RX400 & RX500 too.
    fi


    # CURRENT Volt State for Undervolt
    #voltStateLine=$(($currentCoreState + 1))
    #currentVoltState=$(sudo ./ohgodatool -i $GPUID --show-core | grep -E "VDDC:" | sed -n $voltStateLine"p" | sed 's/^.*entry/entry/' | sed 's/[^0-9]*//g')

    echo "DEBUG: C $currentCoreState / VL $voltStateLine / CVS $currentVoltState"
    echo ""

    if [ "$VDDC" != "skip" ] && [ "$VDDC" != "0" ]; then
      echo "--- Setting up VDDC Voltage GPU$GPUID (VS: $currentVoltState) ---"
      # set all voltage states from 1 upwards to xxx mV:
      #if [ "$maxMemState" != "2" ]
      #then
      #	sudo ./ohgodatool -i $GPUID --volt-state $currentVoltState --vddc-table-set $VDDC
      #else
      #	for voltstate in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15; do
      #		sudo ./ohgodatool -i $GPUID --volt-state $voltstate --vddc-table-set $VDDC
      #	done
      #fi
      currentCoreClock=$(sudo cat /sys/class/drm/card$GPUID/device/pp_dpm_sclk | grep '*' | awk '{ print $2 }' | sed 's/[^0-9]*//g')
      sudo su -c "echo 's 1 $currentCoreClock $VDDC' > /sys/class/drm/card$GPUID/device/pp_od_clk_voltage"
      sudo su -c "echo 's 2 $currentCoreClock $VDDC' > /sys/class/drm/card$GPUID/device/pp_od_clk_voltage"
      sudo su -c "echo 's 3 $currentCoreClock $VDDC' > /sys/class/drm/card$GPUID/device/pp_od_clk_voltage"
      sudo su -c "echo 's 4 $currentCoreClock $VDDC' > /sys/class/drm/card$GPUID/device/pp_od_clk_voltage"
      sudo su -c "echo 's 5 $currentCoreClock $VDDC' > /sys/class/drm/card$GPUID/device/pp_od_clk_voltage"
      sudo su -c "echo 's 6 $currentCoreClock $VDDC' > /sys/class/drm/card$GPUID/device/pp_od_clk_voltage"
      sudo su -c "echo 's 7 $currentCoreClock $VDDC' > /sys/class/drm/card$GPUID/device/pp_od_clk_voltage"
      sudo su -c "echo 's 8 $currentCoreClock $VDDC' > /sys/class/drm/card$GPUID/device/pp_od_clk_voltage"
      #if [ -z "$currentVDDC" ]; then
      #  for voltstate in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15; do
      #    sudo ./ohgodatool -i $GPUID --volt-state $voltstate --vddc-table-set $VDDC
      #  done
      #fi
    fi

    # VDDCI
    if [ "$VDDCI" != "" ] && [ "$VDDCI" != "0" ] && [ "$VDDCI" != "skip" ]; then
      # VDDCI Voltages
      # VDDC Voltage + 50
      echo
      echo "--- Setting up VDDCI Voltage GPU$GPUID ---"
      echo
      sudo ./ohgodatool -i $GPUID --mem-state $maxMemState --vddci $VDDCI
    fi

    # MVDCC
    if [ "$MVDD" != "" ] && [ "$MVDD" != "0" ] && [ "$MVDD" != "skip" ]; then
      echo
      echo "--- Setting up MVDD Voltage GPU$GPUID ---"
      echo
      currentMemoryClock=$(sudo cat /sys/class/drm/card$GPUID/device/pp_dpm_mclk | grep '*' | awk '{ print $2 }' | sed 's/[^0-9]*//g')
      sudo su -c "echo 's 1 $currentMemoryClock $MVDD' > /sys/class/drm/card$GPUID/device/pp_od_clk_voltage"
      sudo su -c "echo 's 2 $currentMemoryClock $MVDD' > /sys/class/drm/card$GPUID/device/pp_od_clk_voltage"
      if [ -z "$currentVDDC" ]; then
        sudo ./ohgodatool -i $GPUID --mem-state $maxMemState --mvdd $MVDD
      fi
    fi

    #################################£
    # SET MEMORY @ CORE CLOCKS

    if [ "$CORECLOCK" != "skip" ]; then
      if [ "$CORECLOCK" != "0" ]; then
        # APPLY AT THE END
        STR5="coreclk:$GPUID=$CORECLOCK"

        if [ -z "$VDDC" ] || [ "$VDDC" = "skip" ]; then
          if [ ! -z "$currentVDDC" ]; then
            VDDC="$currentVDDC"
          else
            VDDC="980"
          fi
        fi

        echo "VDDC => $VDDC"
        sudo su -c "echo 's 1 $CORECLOCK $VDDC' > /sys/class/drm/card$GPUID/device/pp_od_clk_voltage"
        sudo su -c "echo 's 2 $CORECLOCK $VDDC' > /sys/class/drm/card$GPUID/device/pp_od_clk_voltage"
        sudo su -c "echo 's 3 $CORECLOCK $VDDC' > /sys/class/drm/card$GPUID/device/pp_od_clk_voltage"
        sudo su -c "echo 's 4 $CORECLOCK $VDDC' > /sys/class/drm/card$GPUID/device/pp_od_clk_voltage"
        sudo su -c "echo 's 5 $CORECLOCK $VDDC' > /sys/class/drm/card$GPUID/device/pp_od_clk_voltage"
        sudo su -c "echo 's 6 $CORECLOCK $VDDC' > /sys/class/drm/card$GPUID/device/pp_od_clk_voltage"
        sudo su -c "echo 's 7 $CORECLOCK $VDDC' > /sys/class/drm/card$GPUID/device/pp_od_clk_voltage"
        sudo su -c "echo 's 8 $CORECLOCK $VDDC' > /sys/class/drm/card$GPUID/device/pp_od_clk_voltage"

        #if [ -z "$currentVDDC" ]; then
            for corestate in 3 4 5 6 7 8; do
              sudo ./ohgodatool -i $GPUID --core-state $corestate --core-clock $CORECLOCK
            done
        #fi

      fi
    fi


    if [ "$MEMCLOCK" != "skip" ]; then
      if [ "$MEMCLOCK" != "0" ]; then
        # APPLY AT THE END
        STR4="cmemclk:$GPUID=$MEMCLOCK"
        if [ -z "$MVDD" ] || [ "$MVDD" = "skip" ]; then
          if [ ! -z "$currentMVDD" ]; then
            MVDD="$currentMVDD"
          else
            MVDD="980"
          fi
        fi
        echo "MVDD => $MVDD"
        sudo su -c "echo 'm 1 $MEMCLOCK $MVDD' > /sys/class/drm/card$GPUID/device/pp_od_clk_voltage"
        sudo su -c "echo 'm 2 $MEMCLOCK $MVDD' > /sys/class/drm/card$GPUID/device/pp_od_clk_voltage"
        #if [ -z "$currentVDDC" ]; then
          OHGOD2=" --mem-state $maxMemState --mem-clock $MEMCLOCK"
        #fi
      fi
    fi

    #################################£
    # PROTECT FANS, JUST IN CASE
    if [ "$FANSPEED" != 0 ]; then
      OHGOD3=" --set-fanspeed $FANSPEED"
      STR1="--set-fanspeed $FANSPEED"
      STR2="fanspeed:$GPUID=$FANSPEED"
    else
      OHGOD3=" --set-fanspeed 70"
      STR1="--set-fanspeed 70"
      STR2="fanspeed:$GPUID=70"
    fi

    if [ "$FANSPEED" = "skip" ]; then
      OHGOD3=" --set-fanspeed 70"
      STR1="--set-fanspeed 70"
      STR2="fanspeed:$GPUID=70"
    fi

    #################################£
    # Apply Changes
    #sudo ./amdcovc memclk:$GPUID=$MEMCLOCK cmemclk:$GPUID=$MEMCLOCK coreclk:$GPUID=$CORECLOCK ccoreclk:$GPUID=$CORECLOCK $STR2 | grep "Setting"
    #################################£
    # Overwrite PowerPlay to manual
    echo ""
    echo "--- APPLY CURRENT_CLOCKS ---"
    echo "- SET | GPU$GPUID Performance level: manual -"
    echo "- SET | GPU$GPUID DPM state: $currentCoreState -"
    echo "- SET | GPU$GPUID MEM state: $maxMemState -"
    sudo ./ohgodatool -i $GPUID $OHGOD1 $OHGOD3

    sudo su -c "echo 'manual' > /sys/class/drm/card$GPUID/device/power_dpm_force_performance_level"
    sudo su -c "echo $maxCoreState > /sys/class/drm/card$GPUID/device/pp_dpm_sclk"
    sudo su -c "echo $maxMemState > /sys/class/drm/card$GPUID/device/pp_dpm_mclk"

    # comit
    sudo su -c "echo 'c' > /sys/class/drm/card$GPUID/device/pp_od_clk_voltage"
    sudo su -c "echo 'c' > /sys/class/drm/card$GPUID/device/pp_sclk_od"
    echo ""
    echo "NOTICE: If below is empty try to use a 'Supported clock or flash your gpu bios' "
    echo ""

    if [ -z "$GPUINDEX" ]; then
      GPUINDEX="3"
    fi

    if [ "$GPUINDEX" = "skip" ]; then
      GPUINDEX="3"
    fi

    sudo ./rocm-smi -d $GPUID --setsclk $GPUINDEX
    sudo ./rocm-smi -d $GPUID --setmclk 2
    sudo su -c "echo '$GPUINDEX' > /sys/class/drm/card$GPUID/device/pp_dpm_sclk"
    sudo su -c "echo '2' > /sys/class/drm/card$GPUID/device/pp_dpm_mclk"

    sleep 0.2
    sudo ./amdcovc $STR4 $STR5 $STR2 | grep "Setting"

    ##################################
    # CURRENT_Clock Protection
    sudo ./amdcovc memclk:$GPUID=$MEMCLOCK | grep "Setting"
    sudo ./amdcovc ccoreclk:$GPUID=$CORECLOCK | grep "Setting"

    echo "-÷-*-****** ALL *****-*-*÷-"
    sudo su -c "cat /sys/class/drm/card$GPUID/device/pp_od_clk_voltage"
    echo "-÷-*-****** CORE CLOCK *****-*-*÷-"
    sudo su -c "cat /sys/class/drm/card$GPUID/device/pp_dpm_sclk"
    echo "-÷-*-****** MEM  CLOCKS *****-*-*÷-"
    sudo su -c "cat /sys/class/drm/card$GPUID/device/pp_dpm_mclk"


    # Fans for security
    for fid in 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15; do
      TEST=$(cat "/sys/class/drm/card$GPUID/device/hwmon/hwmon$fid/pwm1_max" 2>/dev/null)
      if [ ! -z "$TEST" ]; then
        MAXFAN=$TEST
      fi
    done

    # FANS
    if [ "$FANSPEED" != 0 ]; then
      FANVALUE=$(echo - | awk "{print $MAXFAN / 100 * $FANSPEED}" | cut -f1 -d".")
      FANVALUE=$(printf "%.0f\n" $FANVALUE)
      echo "GPU$GPUID : FANSPEED => $FANSPEED% ($FANVALUE)"
    else
      FANVALUE=$(echo - | awk "{print $MAXFAN / 100 * 70}" | cut -f1 -d".")
      FANVALUE=$(printf "%.0f\n" $FANVALUE)
      echo "GPU$GPUID : FANSPEED => 70% ($FANVALUE)"
    fi

    for fid in 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15; do
      sudo su -c "echo 1 > /sys/class/drm/card$GPUID/device/hwmon/hwmon$fid/pwm1_enable" 2>/dev/null
      sudo su -c "echo $FANVALUE > /sys/class/drm/card$GPUID/device/hwmon/hwmon$fid/pwm1" 2>/dev/null # 70%
    done

  else

    # R9 starts with 0 (zero)
    # Need new FUNC if GPU ID 1, apply to 0 too
    if [ "$GPUID" = "1" ]; then
      echo "-------- ID: 1 ---> Apply to ID: 0 also to make sure -----"
      sudo sh overclock_amd.sh 0 $MEMCLOCK $CORECLOCK $FANSPEED $VDDC $VDDCI $MVDCC
    fi

    echo "== SETTING GPU$GPUID ==="

    if [ "$CORECLOCK" != "skip" ]; then
      if [ "$CORECLOCK" != "0" ]; then
        sudo ./amdcovc coreclk:$GPUID=$CORECLOCK | grep "Setting"
      fi
    fi

    if [ "$MEMCLOCK" != "skip" ]; then
      if [ "$MEMCLOCK" != "0" ]; then
        sudo ./amdcovc memclk:$GPUID=$MEMCLOCK | grep "Setting"
        sudo ./amdcovc memod:$GPUID=20 | grep "Setting"
      fi
    fi

    if [ "$FANSPEED" != 0 ]; then
      sudo ./amdcovc fanspeed:$GPUID=$FANSPEED | grep "Setting"
    else
      sudo ./amdcovc fanspeed:$GPUID=70 | grep "Setting"
    fi

    if [ "$VDDC" != "skip" ]; then
      if [ "$VDDC" != "0" ]; then
        # Divide by 1000 to get mV in V
        VCORE=$(($VDDC / 1000))
        sudo ./amdcovc vcore:$GPUID=$VCORE | grep "Setting"
      fi
    fi

    echo ""

  fi

fi
