#!/bin/bash

# this function guides the user though locale selection using a simple menu
# driven interface.

function locale_selection(){

	echo
	echo "Starting locale selection."

	if [ -f supported_countries ]
	then
		rm supported_countries
	fi

	if [ -f selected_locales ]
	then
		rm selected_locales
	fi

	echo
	echo "Creating searchable list of supported countries..."

	while read line
	do
		if echo $line |
			cut -d, -f2 |
			sed -e 's/[[:space:]]*$//' |
			sed 's/^/_/' |
			grep -q -f - /etc/locale.gen
			then
			echo $line >> supported_countries
		fi
	done < country_codes.csv

	echo "done."

	unset locales[@]

	for (( ; ; ))
	do

		echo
		echo "The following locales will be generated:"
		echo "===> en_US.UTF-8 UTF-8 (Required)"

		for locale in "${locales[@]}"
		do
			echo "===> $locale"
		done

		echo
		echo "1) Add a locale"
		echo "2) Remove a locale"
		echo "3) Finish locale selection"

		read -p "Enter option number: " input

		if (("$input" == 1))
		then

			for (( ; ; ))
			do

				echo
				read -p "Enter all or part of country name: " country

				countries=($(grep -i "$country"  supported_countries))

				unset country_names
				for country in "${countries[@]}"
				do
					country_names+=("$(echo "$country" | sed 's/_/ /g' | cut -d, -f1)")
				done

				if ((${#countries[@]} > 1)); then

					i=1
					echo
					for country in ${countries[@]}
					do
						echo $((i++))")" "$(echo "$country" | sed 's/_/ /g'| cut -d, -f1)"
					done

					echo $i")" "Search again."

					for (( ; ; ))
					do
						read -p "Enter option number: " input

						if (("$input"  <= ${#countries[@]}))
						then
							cnt=$(echo "${countries[$input - 1]}" | cut -d, -f2 | sed 's/[[:space:]]*$//')
							out="true"
							break
						elif (("$input" - 1  == ${#countries[@]}))
						then
							out="false"
							break
						fi
					done

					if [ "$out" == "true" ]
					then
						break
					fi

				elif ((${#countries[@]} == 1))
				then

					for (( ; ; ))
					do

						echo "Found: " "$(echo "${countries[0]}" | cut -d, -f1 | sed -e 's/_/ /g')"

						read -p "Is this correct? (Y/N): " yes_no

						if [ "${yes_no:0:1}" == "y" ] || [ "${yes_no:0:1}" == "Y" ]
						then
							cnt=$(echo "${countries[0]}" | cut -d, -f2 | sed 's/[[:space:]]*$//')
							out="true"
							break
						elif [ "${yes_no:0:1}" == "n" ] || [ "${yes_no:0:1}" == "N" ]
						then
							out="false"
							break
						fi

					done

				if [ "$out" == "true" ]
					then
						break
					fi
				else

					echo "No countries found."
				fi

			done


			langs=($(grep "#" /etc/locale.gen | sed 's/ /./' | cut -d. -f1 | grep "$cnt" | cut -d_ -f1 | sed 's/#//'))

			declare -A uniq
			for k in ${langs[@]}
			do
				uniq[$k]=1
			done

			unique=(${!uniq[@]})

			unset uniq

			echo
			echo "The following languages are supported:"
			i=1
			for lang in ${unique[@]}
			do
				echo $((i++))")" $(grep "#" /etc/locale.gen |
					sed '/^# / d' |
					grep $cnt |
					grep "^#$lang" |
					cut -d_ -f1 |
					sed 's/#/Subtag: /' |
					awk '!seen[$0]++'|
					grep -w -A1 -f - languages.txt |
					awk '/Description/ {for(i=2;i<=NF;i++)printf $i" ";printf "\n"}')
			done

			for (( ; ; ))
			do
				read -p "Enter option number: " input
				if (($input <= ${#unique[@]}  && $input >= 1));
				then
					le=${unique[$input-1]}
					break
				fi
			done


			IFS=$'\n'

			matched_locales=($(grep "#" /etc/locale.gen | grep "^#${le}_${cnt}" | sed 's/#//'))

			if ((${#matched_locales[@]} == 1))
			then

				for (( ; ; ))
				do

					echo
					echo "Found: " "$(echo "${matched_locales[0]}")"

					read -p "Add this locale? (Y/N): " yes_no

					if [ "${yes_no:0:1}" == "y" ] || [ "${yes_no:0:1}" == "Y" ]
					then
						if $(echo "$locales"  | grep -q "${matched_locales[0]}")
						then
							break
						else
							locales+=(${matched_locales[0]})
							out="true"
						fi
						break
					elif [ "${yes_no:0:1}" == "n" ] || [ "${yes_no:0:1}" == "N" ]
					then
						out="false"
						break
					fi

				done


			elif ((${#matched_locales[@]} > 1))
			then
				i=1
				echo
				echo "Select a locale (UTF-8 character sets are preferred):"
				for loc in ${matched_locales[@]}
				do
					echo "$((i++))"") " "$loc"
				done
					echo "$((i++))"") " "Cancel"

				for (( ; ; ))
				do
					read -p "Choose option number: " input

					if (("$input" <= ${#matched_locales[@]} && "$input" > 0))
					then
						if $(echo "$locales"  | grep -q "${matched_locales["$input" - 1]}")
						then
							break
						else
							locales+=(${matched_locales["$input" - 1]})
							break
						fi
					elif (("$input" == 3))
					then
						break
					fi
				done
			fi

			unset IFS
		elif (("$input" == 2 && ${#locales[@]} >= 1))
		then
			echo
			echo "Select locale to remove:"
			i=1
			for locale in "${locales[@]}"
			do
				echo "$((i++))"") " "$locale"
			done
			for (( ; ; ))
			do
				read -p "Enter option number:" input
				if (($input <= "${#locales[@]}" && "$input" > 0))
				then
					unset 'locales[$input - 1]'
					break
				fi
			done
		elif (("$input" == 3))
		then
			locales+=("en_US.UTF-8 UTF-8")
			printf "%s\n" "${locales[@]}" >> selected_locales
			break
		fi
	done

	echo
	echo "Finished locale selection."
}

#locale_selection

while read line
do
	echo \#{$line}
	sed -i "s/\#$line/$line/g" locale.gen
done < selected_locales
