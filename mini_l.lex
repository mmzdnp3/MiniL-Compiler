/*
*	CS 152 
*	Project Phase 1
*	Ikk Anmol Singh Hundal  <861134450>
*	Chwan-Hao Tung 			<861052182>
*/

%{
	#include "y.tab.h"
	#include <string.h>
	#include <stdlib.h>
	int line = 1, pos = 1;
%}

DIGIT    [0-9]
LETTER   [a-zA-Z]
   
%%

##.*  							{/*ignore comments */	pos += yyleng;}

"program"						{pos += yyleng;return PROGRAM;}
"beginprogram"					{pos += yyleng;return BEGIN_PROGRAM;}
"endprogram"            		{pos += yyleng;return END_PROGRAM;}
"integer"            			{pos += yyleng;return INTEGER;}
"array"            				{pos += yyleng;return ARRAY;}
"of"            				{pos += yyleng;return OF;}
"if"            				{pos += yyleng;return IF;}
"then"            				{pos += yyleng;return THEN;}
"endif"            				{pos += yyleng;return ENDIF;}
"else"            				{pos += yyleng;return ELSE;}
"while"            				{pos += yyleng;return WHILE;}
"do"            				{pos += yyleng;return DO;}
"beginloop"            			{pos += yyleng;return BEGINLOOP;}
"endloop"            			{pos += yyleng;return ENDLOOP;}
"continue"            			{pos += yyleng;return CONTINUE;}
"read"            				{pos += yyleng;return READ;}
"write"            				{pos += yyleng;return WRITE;}
"and"            				{pos += yyleng;return AND;}
"or"            				{pos += yyleng;return OR;}
"not"            				{pos += yyleng;return NOT;}
"true"            				{pos += yyleng;return TRUE;}
"false"            				{pos += yyleng;return FALSE;}


"-"            			{pos += yyleng;return SUB;}
"+"            			{pos += yyleng;return ADD;}
"*"            			{pos += yyleng;return MULT;}
"/"            			{pos += yyleng;return DIV;}
"%"            			{pos += yyleng;return MOD;}


"=="            			{pos += yyleng;return EQ;}
"<>"            			{pos += yyleng;return NEQ;}
"<"            				{pos += yyleng;return LT;}
">"            				{pos += yyleng;return GT;}
"<="            			{pos += yyleng;return LTE;}
">="            			{pos += yyleng;return GTE;}

{DIGIT}+       											{yylval.number = atoi(yytext); pos += yyleng; return NUMBER;}
{LETTER}({LETTER}|{DIGIT}|_)*_							{printf("Error at line %d, column %d: identifier \"%s\" cannot end with an underscore",line, pos, yytext); exit(0);}
{LETTER}(({LETTER}|{DIGIT}|_)*({LETTER}|{DIGIT}))?		{	yylval.string = malloc(strlen(yytext)+1);
															strcpy(yylval.string,yytext); pos+=yyleng; return IDENT;}
{DIGIT}+{LETTER}*          								{printf("Error at line %d, column %d: identifier \"%s\" must begin with a letter\n", line, pos, yytext);exit(0);}

";"								{pos += yyleng;return SEMICOLON;}
":"								{pos += yyleng;return COLON;}
","								{pos += yyleng;return COMMA;}
"("								{pos += yyleng;return L_PAREN;}
")"								{pos += yyleng;return R_PAREN;}
":="							{pos += yyleng;return ASSIGN;}
[ \t]+         					{/* ignore whitespaces */; pos += yyleng;}
"\n"							{line++; pos =0;}
.              					{printf("Error at line %d, column %d: unrecognized symbol \"%s\"\n", line, pos, yytext);
									yylval.string = malloc(strlen(yytext)+1);
									strcpy(yylval.string,yytext); pos+=yyleng; return UNRECOGNIZED;}
