#!/bin/bash

#-------------- Секция инициализации --------------

SYSTEMS=("rls" "zrdn" "spro" "kp")
SYSTEMSDESCR=("РЛС" "ЗРДН" "СПРО")
HBVARS=("-1" "-1" "-1")
LOGLINES=("0" "0" "0")

STRTODEL=20
STRMAXCOUNT=100

source "data.sh"
source "methods.sh"

SubsystemType="КП"
SubsystemLog="KP"
NumberOfSystem=0
SubsystemCanShoot=(0 0 0) # 0-ББ БР 1-Самолеты 2-Крылатые ракеты

commfile="$DirectoryCommLog/kp.log"
CheckStart

trap sigint_handler 2 		# Отлов сигнала остановки процесса. Если сигнал пойман, то вызывается функция ...

echo "Система $SubsystemType успешно инициализирована!"
echo "Система $SubsystemType успешно инициализирована!" >>$commfile

sltime=0;

#-------------- Секция работы КП --------------

while :
do
	sleep 1
	let sltime+=1

	# Вывод логов
  if (( sltime%2 == 0))		# Если счётчик кратен 2м, то ...
	then
		i=0
		while (( $i < 3 ))		# Цикл по подсистемам
		do
			lines=`wc -l "$DirectoryCommLog/${SYSTEMS[$i]}.log" 2>/dev/null`; res=$? 	# Получаем количество строк в лог файле
			if (( res == 0 ))				# Если количество строк удалось получить, то
			then
				count=($lines); count=${count[0]}			#
				((LinesToDisplay=$count-${LOGLINES[$i]})); LOGLINES[$i]=$count; 
				if (( $LinesToDisplay > 0))
				then
					readedfile=`tail -n $LinesToDisplay $DirectoryCommLog/${SYSTEMS[$i]}.log 2>/dev/null`;result=$?;
					if (( $result == 0 ))
					then
						echo "$readedfile" | base64 -d
					fi
				fi
			fi
			let i+=1
		done
	fi

	# maintain all systems state
  if (( sltime%30 == 0))
	then
		echo "Запуск проверки всех систем"
		echo "Запуск проверки всех систем" >>$commfile
		i=0
		while (( $i < 3 ))
		do
			readedfile=`tail $DirectoryComm/${SYSTEMS[$i]} 2>/dev/null`; result=$?;
			if (( $result == 0 ))
			then
				if (( ${HBVARS[$i]} == $readedfile))
				then
					# echo "${HBVARS[$i]}"
					# echo "$readedfile"
					echo "  Система ${SYSTEMSDESCR[$i]} зависла или оcтановлена."
					echo "  Система ${SYSTEMSDESCR[$i]} зависла или оcтановлена." >>$commfile
				else
					if (( ${HBVARS[$i]} == -1 ))
					then
						echo "  Получено начальное состояние сиcтемы ${SYSTEMSDESCR[$i]}."
						echo "  Получено начальное состояние сиcтемы ${SYSTEMSDESCR[$i]}." >>$commfile
					else
						echo "  Сиcтема ${SYSTEMSDESCR[$i]} работает в штатном режиме."
						echo "  Сиcтема ${SYSTEMSDESCR[$i]} работает в штатном режиме." >>$commfile
					fi
				fi
				HBVARS[$i]=$readedfile
			else
				echo "  Ошибка доступа к cиcтеме ${SYSTEMSDESCR[$i]}. Система неинициализирована или недоступна." # Было i+2
				echo "  Ошибка доступа к cиcтеме ${SYSTEMSDESCR[$i]}. Система неинициализирована или недоступна." >>$commfile
			fi
			let i+=1
		done
	fi

	# delete old log entries
  if (( sltime%10 == 0))
	then
		i=0
		while (( $i < 4 ))
		do
			lines=`wc -l "$DirectoryCommLog/${SYSTEMS[$i+1]}.log" 2>/dev/null`; res=$?
			if (( res == 0 ))
			then
				count=($lines); count=${count[0]}
				if (( $count >= $STRMAXCOUNT ))
				then
					echo "Файл ${SYSTEMS[$i]}.log. Строк $count. Допустимо $STRMAXCOUNT. Удаление первых $STRTODEL строк."
					echo "Файл ${SYSTEMS[$i]}.log. Строк $count. Допустимо $STRMAXCOUNT. Удаление первых $STRTODEL строк." >>$commfile

					deleted=`sed "1,$STRTODEL d" /tmp/GenTargets/CommLog/${SYSTEMS[$i]}.log`
					echo "$deleted" >/tmp/GenTargets/CommLog/${SYSTEMS[$i]}.log
					((LOGLINES[$i]=${LOGLINES[$i]}-$STRTODEL))
				fi				
			fi
			let i+=1
		done
	fi
done
