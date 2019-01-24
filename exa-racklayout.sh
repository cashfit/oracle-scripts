#!/bin/bash
# Fred Denis -- Jan 2019 -- http://unknowndba.blogspot.com -- fred.denis3@gmail.com
#
# Show what's on an Exadata based on the /opt/oracle.SupportTools/onecommand/databasemachine.xml file
# The output shows each Exadata component, their IP, ILOM and ILOM IP on the form of an Exadata Rack layout
#
# More information on
#
# The current version of the script is 20190124
#
# 20190124 - Fred Denis - Initial Release
#

#
# The databasemachine.xml file we base our report on
#
DBMACHINE=/opt/oracle.SupportTools/onecommand/databasemachine.xml

if [ ! -f ${DBMACHINE} ] || [ ! -r ${DBMACHINE} ]
then
        cat << !
        The ${DBMACHINE} cannot be found or is not readable, cannot continue.
!
        exit 123
fi
printf "\n"

awk 'BEGIN\
        {       FS="<|>"                                                                ;
                # some colors
             COLOR_BEGIN =       "\033[1;"                                              ;
               COLOR_END =       "\033[m"                                               ;
                # Foreground colors code
                   WHITE =       "37m"                                                  ;
                  NORMAL =       "0m"                                                   ;
                # Background colors code
                    BLUE =       "44m"                                                  ;
                   GREEN =       "42m"                                                  ;
                  YELLOW =       "43m"                                                  ;
                     RED =       "41m"                                                  ;

                   COL_U =       3                                                      ;       # Size of the "U" column
        }
        #
        # A function to center the outputs with colors
        #
        function center( str, n, color, sep)
        {       right = int((n - length(str)) / 2)                                      ;
                left  = n - length(str) - right                                         ;
                return sprintf(COLOR_BEGIN color "%" left "s%s%" right "s" COLOR_END sep, "", str, "" )        ;
        }
        #
        # A function that just print a "---" white line
        #
        function print_a_line(size)
        {
                if ( ! size)
                {       size = COL_DB+COL_VER+(COL_NODE*n)+COL_TYPE+n+3                 ;
                }
                printf("%s", COLOR_BEGIN WHITE)                                         ;
                for (k=1; k<=size; k++) {printf("%s", "-");}                            ;
                printf("%s", COLOR_END"\n")                                             ;
        }
        {       if ($2 == "RACKS")
                {       while (getline)
                        {       if ($2 == "MACHINETYPES")       {MODEL=$3       ;}
                                if ($2 == "MACHINEUSIZE")       { NB_U=$3       ;}
                                if ($2 == "ITEMS")              {ITEMS=$3       ; break ;}
                        }
                }
                if ($2 ~ /ITEM ID/)
                {       info="" ;
                        while (getline)
                        {       if ($2 == "TYPE")               {TYPE=$3        ;}
                                if (info == "") {info=$3;}      else {info=info";"$3    ;}
                                if ($2 == "ADMINNAME")          {if (length($3) > MAX_COL1) {MAX_COL1 = length($3)}}
                                if ($2 == "ADMINIP")            {if (length($3) > MAX_COL2) {MAX_COL2 = length($3)}}
                                if ($2 == "ILOMNAME")           {if (length($3) > MAX_COL3) {MAX_COL3 = length($3)}}
                                if ($2 == "ILOMIP")             {if (length($3) > MAX_COL4) {MAX_COL4 = length($3)}}
                                if ($2 == "ULOCATION")          {ULOC=$3        ;}
                                if ($2 == "/ITEM")              {tab[ULOC]=info ;break  ;       }
                        }
                }
        }
        END\
        {       # To have a space with the right table separator
                COL_U++                                                                 ;
                MAX_COL1++                                                              ;
                MAX_COL2++                                                              ;
                MAX_COL3++                                                              ;
                MAX_COL4++                                                              ;
                line_size=COL_U+MAX_COL1+MAX_COL2+MAX_COL3+MAX_COL4+10                  ;       # Size of the "---" lines

                printf("%s\n\n", center(MODEL, line_size, WHITE))                       ;

                #Header
                printf("%s|", center("U" ,  COL_U+1, WHITE))                            ;
                printf("%s|", center("Hostname", MAX_COL1+1, WHITE))                    ;
                printf("%s|", center("Host IP", MAX_COL2+1, WHITE))                     ;
                printf("%s|", center("ILOM name", MAX_COL3+1, WHITE))                   ;
                printf("%s|", center("ILOM IP", MAX_COL4+1, WHITE))                     ;
                printf "\n"     ;
                print_a_line(line_size)                                                 ;

                for (i=NB_U; i>=1; i--)
                {
                        split (tab[i], to_print, ";")                                   ;
                        ui="U"i ;

                        color=NORMAL                                                    ;
                        if (to_print[2] != "")
                        {
                                if (to_print[1] == "computenode") {color=BLUE}          ;
                                if (to_print[1] == "cellnode")    {color=RED}           ;
                                if (to_print[1] == "ib")          {color=YELLOW}        ;
                                if (to_print[1] == "cisco")       {color=GREEN}         ;
                        }
                        if (to_print[1] == "")
                        {
                                if (tab[i-1] ~ /cellnode/)
                                {       split(tab[i-1], temp, ";")                      ;
                                        if (temp[2] != "") {color=RED}                  ;
                                }
                        }

                        printf(COLOR_BEGIN color "%s", "")                              ;
                        printf(" %-"COL_U"s|", ui);                                     ;       # U
                        printf(" %-"MAX_COL1"s|", to_print[2])                          ;       # Hostname
                        printf(" %-"MAX_COL2"s|", to_print[3])                          ;       # Host IP
                        if (to_print[1] ~ /node/)
                        {
                                to_print_col3 = to_print[4]                             ;
                                to_print_col4 = to_print[5]                             ;
                        } else {
                                to_print_col3 = ""                                      ;
                                to_print_col4 = ""                                      ;
                        }
                        printf(" %-"MAX_COL3"s|", to_print_col3)                        ;       # ILOM name
                        printf(" %-"MAX_COL4"s|", to_print_col4)                        ;       # ILOM IP
                        printf(COLOR_END "%s", "")                                      ;
                        printf "\n"                                                     ;
                }
                print_a_line(line_size)                                                 ;
                printf "\n"                                                             ;

                # A legend to explain the colors
                printf("%s", "   ")     ;
                printf(COLOR_BEGIN BLUE"%s"COLOR_END, "Database Servers")               ;
                printf("%s", "   ")     ;
                printf(COLOR_BEGIN RED"%s"COLOR_END, "Storage Servers")                 ;
                printf("%s", "   ")     ;
                printf(COLOR_BEGIN YELLOW"%s"COLOR_END, "IB Switches")                  ;
                printf("%s", "   ")     ;
                printf(COLOR_BEGIN GREEN"%s"COLOR_END, "Cisco Switch")                  ;
                printf "\n\n"                                                           ;
        }
' ${DBMACHINE}

#*********************************************************************************************************
#                               E N D     O F      S O U R C E
#*********************************************************************************************************
