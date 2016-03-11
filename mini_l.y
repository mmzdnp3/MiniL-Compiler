/*
*	CS 152
*	Project Phase 2
*	Ikk Anmol Singh Hundal  <861134450>
*	Chwan-Hao Tung 			<861052182>
*/

%{
	#include <stdio.h>
	#include <stdlib.h>
    #include <map>
    #include <set>
    #include <string>
    #include <vector>
    #include <stack>
    #include <iostream>
    #include <algorithm>
    #include <sstream>
    #include <string.h>
        
    using namespace std;

	void yyerror(const char *msg);
	int yylex();
	extern int line;
	extern int pos;
	extern FILE * yyin;

    class MiniVal{
        public:
            char type;
            int size;
            MiniVal(char type, int size=0)
            :type(type), size(size){}
    };
    
    class MiniVar{
        public:
            string name;
            char type;
            string index;
            MiniVar(string name, char type, string index="")
            :name(name), type(type), index(index){}
    };

    vector<string> program_vec;
    map<string, MiniVal> symbol_table;
    vector<string> declarations;
    vector<MiniVar> var_vector;
    stack<string> if_label_stack;
    stack<string> loop_label_stack;

    /* List of defines for generateInstruction() One for each syntax */
    #define OP_VAR_DEC 0
    #define OP_ARR_VAR_DEC 1
    #define OP_COPY_STATEMENT 2
    #define OP_ARR_ACCESS_SRC 3 
    #define OP_ARR_ACCESS_DST 4
    #define OP_STD_IN 5
    #define OP_STD_IN_ARR 6
    #define OP_STD_OUT 7
    #define OP_STD_OUT_ARR 8
    #define OP_ADD 9
    #define OP_SUB 10
    #define OP_MULT 11
    #define OP_DIV 12
    #define OP_MOD 13
    #define OP_LT 14
    #define OP_LTE 15
    #define OP_NEQ 16
    #define OP_EQ 17
    #define OP_GTE 18
    #define OP_GT 19
    #define OP_OR 20
    #define OP_AND 21
    #define OP_NOT 22
    #define OP_LABEL_DEC 23
    #define OP_GOTO 24
    #define OP_IF_GOTO 25
    
    #define ARRAY_VAR 100
    #define NUMBER_VAR 101
    #define IDENT_VAR 102
	
    /*Function prototypes*/
    void checkAndInsertDeclaration(string);
    string generateInstruction( int, string, string, string);
    void addInstruction(int, string, string, string);
    void writeToFile(string);
	

    /* Helper functions */
    void newPredicate(string & str);
    void newTemp(string &str);
    void newLabel(string &str);
%}


%union{
	int number;
	char* string;
	const char* const_string;
	
	struct attributes
	{
		const char* name;
		char type;
		const char* index;
	};

	
	struct attributes attributes;
}


%error-verbose
%start input
%token PROGRAM
%token BEGIN_PROGRAM
%token END_PROGRAM
%token INTEGER
%token ARRAY
%token OF
%token IF
%token THEN
%token ENDIF
%token ELSE
%token WHILE
%token DO
%token BEGINLOOP
%token ENDLOOP
%token CONTINUE
%token READ
%token WRITE
%token AND
%token OR
%token NOT
%token TRUE
%token FALSE
%token SUB
%token ADD
%token MULT
%token DIV
%token MOD
%token EQ
%token NEQ
%token LT
%token GT
%token LTE
%token GTE
%token SEMICOLON
%token COLON
%token COMMA
%token L_PAREN
%token R_PAREN
%token ASSIGN
%token <number> NUMBER
%token <string> IDENT
%token <string> UNRECOGNIZED
%right ASSIGN
%right COLON
%left OR
%left AND
%right NOT
%left EQ NEQ LT GT LTE GTE
%left SUB ADD
%left MULT DIV MOD
%left L_PAREN R_PAREN

%type<attributes> var
%type<const_string> expression multiplicative_exp term comp bool_exp relation_exp
					relation_and_exp;

%%
			
	input:
		    program_declaration   SEMICOLON   block   END_PROGRAM
                {
                    map<string, MiniVal>::iterator it; 
                    for(it=symbol_table.begin(); it!=symbol_table.end();++it){
                        if(it->second.type == 'I')
                            cout << "\t. " << it->first << endl;
                        else if(it->second.type == 'A')
                            cout << "\t.[] " << it->first << ", " << it->second.size << endl;
                    }
                    for(int i=0; i<(int)program_vec.size();++i)
                        cout << program_vec[i] << endl;
                }
			;

    program_declaration: 
            PROGRAM IDENT
                {
                    symbol_table.insert(pair<string, MiniVal>(string($2), MiniVal('P')) );
                }
            ;            
            
			
	block:     
			declarations   begin_program   statements
				{}
			;
				
	declarations: 
	        declaration   SEMICOLON declarations
				{}
			| declaration   SEMICOLON
				{}
			;
			
	declaration:          
	        indentifiers   COLON    INTEGER 
                {
                    while(!declarations.empty())
                    {
                        string x = declarations.back();
                        declarations.pop_back();
                        symbol_table.insert(pair<string, MiniVal>(x, MiniVal('I')) );
                    }
                }
			| indentifiers   COLON    ARRAY   L_PAREN   NUMBER   R_PAREN   OF  INTEGER
                {
                    while(!declarations.empty())
                    {
                        string x = declarations.back();
                        declarations.pop_back();
                        symbol_table.insert(pair<string, MiniVal>(x, MiniVal('A', $5)) );
                    }
                }
			;
	
	indentifiers:
	        IDENT  COMMA	indentifiers
				{
					checkAndInsertDeclaration(string($1));
				}
			| IDENT
				{
					checkAndInsertDeclaration(string($1));
				}
			;

    if_then_part:
            IF bool_exp THEN
                {
                    string trueLabel;
                    string falseLabel;
                    newLabel(trueLabel);
                    newLabel(falseLabel);
                    addInstruction(OP_IF_GOTO, trueLabel, $2, "");
                    addInstruction(OP_GOTO, falseLabel, "", "");
                    addInstruction(OP_LABEL_DEC, trueLabel, "", "");
                    if_label_stack.push(falseLabel);
                }  
            ;
			
	statement:
			var   ASSIGN   expression											
				{
					if($1.type == ARRAY_VAR)
					{
						addInstruction(OP_ARR_ACCESS_DST, $1.name, $1.index , $3);
					}
					else{
					    addInstruction(OP_COPY_STATEMENT,string($1.name), $3,"");
					}
				}
			| if_then_part  statements   ENDIF
                {
                    addInstruction(OP_LABEL_DEC, if_label_stack.top(), "", "");
                    if_label_stack.pop();
                }
			| if_then_part  statements  ELSE
                {
                    string endLabel;
                    newLabel(endLabel);
                    addInstruction(OP_GOTO, endLabel, "", "");
                    addInstruction(OP_LABEL_DEC, if_label_stack.top(), "", "");
                    if_label_stack.pop();
                    if_label_stack.push(endLabel);
                } 
                statements   ENDIF 	
                {
                    addInstruction(OP_LABEL_DEC, if_label_stack.top(), "", "");
                    if_label_stack.pop();
                }
		    
            | WHILE
                {
                    string loopLabel;
                    newLabel(loopLabel);
                    addInstruction(OP_LABEL_DEC, loopLabel, "", "");
                    loop_label_stack.push(loopLabel);
                }   
                bool_exp 
                {
                    string trueLabel;
                    string falseLabel;
                    newLabel(trueLabel);
                    newLabel(falseLabel);
                    addInstruction(OP_IF_GOTO, trueLabel, $3, "");
                    addInstruction(OP_GOTO, falseLabel, "", "");
                    addInstruction(OP_LABEL_DEC, trueLabel, "", "");
                    string loopLabel = loop_label_stack.top();
                    loop_label_stack.pop();
                    loop_label_stack.push(falseLabel);
                    loop_label_stack.push(loopLabel);
                }  
                BEGINLOOP   statements   ENDLOOP 
                {
                    addInstruction(OP_GOTO, loop_label_stack.top(), "", "");
                    loop_label_stack.pop();
                    addInstruction(OP_LABEL_DEC, loop_label_stack.top(), "", "");
                    loop_label_stack.pop();
                }
			| DO 
                {
                    string loopLabel;
                    newLabel(loopLabel);
                    addInstruction(OP_LABEL_DEC, loopLabel, "", "");
                    loop_label_stack.push(loopLabel);
                }  
                BEGINLOOP   statements   ENDLOOP   WHILE    bool_exp 		
                {
                    addInstruction(OP_IF_GOTO, loop_label_stack.top(), $7, "");
                    loop_label_stack.pop();
                }
			| READ   vars 													
				{
					while(!var_vector.empty())
					{
						MiniVar myvar = var_vector.back();
                        if(myvar.type == 'A')
                        {
                            addInstruction(OP_STD_IN_ARR, myvar.name, myvar.index ,"" );
                        }
                        else
                        {
						    addInstruction(OP_STD_IN, myvar.name,"","");
                        }
						var_vector.pop_back();
					}
				}
			| WRITE   vars 
				{
					while(!var_vector.empty())
					{
						MiniVar myvar = var_vector.back();
                        if(myvar.type == 'A')
                        {
                            addInstruction(OP_STD_OUT_ARR, myvar.name, myvar.index ,"" );
                        }
                        else
                        {
						    addInstruction(OP_STD_OUT, myvar.name,"","");
                        }
						var_vector.pop_back();
                    /*
						string var_name = var_vector.back().first;
						var_vector.pop_back();
						addInstruction(OP_STD_OUT,var_name,"","");
                        */
					}
				}
			| CONTINUE
				{
                    addInstruction(OP_GOTO, loop_label_stack.top(), "", "");
                }
			;
		
	vars:
			var    COMMA    vars 	
				{
					if($1.type == ARRAY_VAR)
					    var_vector.push_back(MiniVar(string($1.name),'A', string($1.index)));
                    else
					    var_vector.push_back(MiniVar(string($1.name),'I', ""));
				}
			| var 
				{
					if($1.type == ARRAY_VAR)
					    var_vector.push_back(MiniVar(string($1.name),'A', string($1.index)));
                    else
					    var_vector.push_back(MiniVar(string($1.name),'I', ""));
				}
			;
		
	statements:
			statement   SEMICOLON 				
				{}
			| statements   statement	SEMICOLON		
				{}
			;
	
	bool_exp:
			relation_and_exp
				{
					$$ = strdup($1);
				}
			| bool_exp	OR  relation_and_exp
				{
					string predicate;
					newPredicate(predicate);
					addInstruction(OP_OR, predicate, $1, $3);
					$$ = strdup(predicate.c_str());
				}
			;
			
	relation_and_exp:
			relation_exp
				{
					$$ = strdup($1);
				}
			| relation_and_exp  AND relation_exp 	
				{
					string predicate;
					newPredicate(predicate);
					addInstruction(OP_AND, predicate, $1, $3);
					$$ = strdup(predicate.c_str());
				}
			;
	
	relation_exp:
			expression	comp	expression 			
				{
					string predicate;
					newPredicate(predicate);
					if(strcmp($2, "EQ")==0)
					{
						addInstruction(OP_EQ, predicate, $1, $3);
					}
					if(strcmp($2, "NEQ")==0)
					{
						addInstruction(OP_NEQ, predicate, $1, $3);
					}
					if(strcmp($2, "LT")==0)
					{
						addInstruction(OP_LT, predicate, $1, $3);
					}
					if(strcmp($2, "GT")==0)
					{
						addInstruction(OP_GT, predicate, $1, $3);
					}
					if(strcmp($2, "LTE")==0)
					{
						addInstruction(OP_LTE, predicate, $1, $3);
					}
					if(strcmp($2, "GTE")==0)
					{
						addInstruction(OP_GTE, predicate, $1, $3);
					}
					$$ = strdup(predicate.c_str());
				}
			| TRUE									
				{
					$$ = strdup("1");
				}
			| FALSE 				
				{
					$$ = strdup("0");
				}
			| L_PAREN	bool_exp	R_PAREN 		
				{
					$$ = strdup($2);
				}
			| NOT expression	comp	expression
				{
					string predicate;
					newPredicate(predicate);
					addInstruction(OP_NOT, predicate, $2, "");
					if(strcmp($3, "EQ")==0)
					{
						addInstruction(OP_EQ, predicate, predicate, $4);
					}
					if(strcmp($3, "NEQ")==0)
					{
						addInstruction(OP_NEQ, predicate, predicate, $4);
					}
					if(strcmp($3, "LT")==0)
					{
						addInstruction(OP_LT, predicate, predicate, $4);
					}
					if(strcmp($3, "GT")==0)
					{
						addInstruction(OP_GT, predicate, predicate, $4);
					}
					if(strcmp($3, "LTE")==0)
					{
						addInstruction(OP_LTE, predicate, predicate, $4);
					}
					if(strcmp($3, "GTE")==0)
					{
						addInstruction(OP_GTE, predicate, predicate, $4);
					}
					$$ = strdup(predicate.c_str());
				}
			| NOT TRUE 
				{
					$$ = strdup("0");
				}
			| NOT FALSE 							
				{
					$$ = strdup("1");
				}
			| NOT L_PAREN   bool_exp   R_PAREN 		
				{
					string predicate;
					newPredicate(predicate);
					addInstruction(OP_NOT, predicate, $3, "");
					$$ = strdup(predicate.c_str());
				}
			;
			
	comp:
			EQ 					
				{
					$$ = strdup("EQ");
				}
			| NEQ 				
				{
					$$ = strdup("NEQ");
				}
			| LT 				
				{
					$$ = strdup("LT");
				}
			| GT 				
				{
					$$ = strdup("GT");
				}
			| LTE 	            
				{
					$$ = strdup("LTE");
				}
			| GTE	            
				{
					$$ = strdup("GTE");
				}
			;
	
	expression:
			multiplicative_exp
				{
					$$ = strdup($1);
				}
			| expression    ADD   multiplicative_exp	
				{
					string mulexp = $3;
					string expre = $1;
					string temp;
					newTemp(temp);
					addInstruction(OP_ADD, temp, $1, mulexp);
					$$ = strdup(temp.c_str());
				}
			| expression    SUB   multiplicative_exp
				{
					string mulexp = $3;
					string temp;
					newTemp(temp);
					addInstruction(OP_SUB, temp, $1, mulexp);
					$$ = strdup(temp.c_str());
				}
			;
			
	multiplicative_exp:
			term   
				{
					$$ = strdup($1);
				}
			| multiplicative_exp  MULT  term
				{
					string mulexp = $3;
					string temp;
					newTemp(temp);
					addInstruction(OP_MULT, temp, $1, mulexp);
					$$ = strdup(temp.c_str());
				}
			| multiplicative_exp	DIV   term  
				{
					string mulexp = $3;
					string temp;
					newTemp(temp);
					addInstruction(OP_DIV, temp, $1, mulexp);
					$$ = strdup(temp.c_str());
				}
			| multiplicative_exp	 MOD   term  
				{
					string mulexp = $3;					
					string temp;
					newTemp(temp);
					addInstruction(OP_MOD, temp, $1, mulexp);
					$$ = strdup(temp.c_str());
				}
			;
			
	term:
			var										
				{
					if($1.type == ARRAY_VAR)
					{
						string temp;
						newTemp(temp);
						addInstruction(OP_ARR_ACCESS_SRC, temp, $1.name , $1.index);
						$$ = strdup(temp.c_str());
					}
					else{
						$$ = strdup($1.name);
					}
				}
			| NUMBER								
				{
					stringstream ss;
					string tmp;
					ss << $1;
					tmp = ss.str();
					$$ = strdup(tmp.c_str());
				}
			| L_PAREN   expression R_PAREN			
				{
					$$ = strdup($2);
				}
			| SUB   var
				{
					if($2.type == ARRAY_VAR)
					{
						string temp;
						newTemp(temp);
						addInstruction(OP_ARR_ACCESS_SRC, temp, $2.name , $2.index);
						addInstruction(OP_SUB, temp, "0" , temp);
						$$ = strdup(temp.c_str());
					}
					else
					{
						addInstruction(OP_SUB, $2.name, "0" , $2.name);
						$$ = strdup($2.name);
					}
				}
			| SUB   NUMBER
				{
					int t = $2;
					t = -t;
					stringstream ss;
					string tmp;
					ss << t;
					tmp = ss.str();
					$$ = strdup(tmp.c_str());
					
				}
			| SUB   L_PAREN   expression R_PAREN
				{
					addInstruction(OP_SUB, $3, "0" , $3);
					$$ = strdup($3);
					
				}
			;
			
	var:
			IDENT
				{
					map<string, MiniVal>::iterator it;
					it = symbol_table.find(string($1));

					/*Check if var declared or not*/
					if(it == symbol_table.end())
					{
						string errstr = "Undeclared variable " + string($1);
						yyerror(errstr.c_str());
						exit(0);
					}
                    else
                    {
					    /*Check if var is an array or not*/
                        if(it->second.type == 'A'){
						    string errstr = "Trying to use array " + string($1) + " as a Regular ";
						    yyerror(errstr.c_str());
						    exit(0);
                        }
                    }

					$$.name = $1;
					$$.type = IDENT_VAR;
					$$.index = NULL;
				}
			| IDENT   L_PAREN   expression   R_PAREN
				{
					map<string, MiniVal>::iterator it;
					it = symbol_table.find(string($1));

					/*Check if var declared or not*/
					if(it == symbol_table.end())
					{
						string errstr = "Undeclared variable " + string($1);
						yyerror(errstr.c_str());
						exit(0);
					}
                    else
                    {
					    /*Check if var is an array or not*/
                        if(it->second.type != 'A'){
						    string errstr = "Trying to use regular " + string($1) + " as an Array ";
						    yyerror(errstr.c_str());
						    exit(0);
                        }
                    }

                    $$.name = $1;
                    $$.type = ARRAY_VAR;
                    $$.index = $3;
                }
			;

    begin_program:
            BEGIN_PROGRAM {program_vec.push_back(": START");}

%%


int main(int argc, char **argv)
{
   yyparse();
   return 0;
}


void yyerror(const char *msg)
{
   printf("**Line %d %s\n", line, msg);
}


void checkAndInsertDeclaration(string identName){

    if( (find(declarations.begin(), declarations.end(), identName) != declarations.end())
        || (symbol_table.find(identName) != symbol_table.end() )) {
        string errstr = "Multiple Declarations with identifier " + identName;
        yyerror(errstr.c_str());
        exit(0);
    }
    declarations.push_back(identName);

}

/* Given the instruction and operands, fill the value of newNode with the corresponding syntax */

string generateInstruction(int INSTR_VALUE, string op1, string op2="", string op3="")
{
    char instr[254];
    const char * operand1 = op1.c_str();
    const char * operand2 = op2.c_str();
    const char * operand3 = op3.c_str();
	switch(INSTR_VALUE)
	{
		/*Ex: If the instruction is variable declaration*/
		case(OP_VAR_DEC):
		{
			/*Set instr to be ". name", in which name is operand1 */
			sprintf(instr, "\t. %s", operand1);
			break;
		}
		case(OP_ARR_VAR_DEC):
		{
			sprintf(instr, "\t.[] %s, %s", operand1, operand2);
			break;
		}
		case(OP_COPY_STATEMENT):
		{
			sprintf(instr, "\t= %s, %s", operand1, operand2);
			break;
		}
		case(OP_ARR_ACCESS_SRC):
		{
			sprintf(instr, "\t=[] %s, %s, %s", operand1, operand2, operand3);
			break;
		}
		case(OP_ARR_ACCESS_DST):
		{
			sprintf(instr, "\t[]= %s, %s, %s", operand1, operand2, operand3);
			break;
		}
		case(OP_STD_IN):
		{
			sprintf(instr, "\t.< %s", operand1);
			break;
		}
		case(OP_STD_IN_ARR):
		{
			sprintf(instr, "\t.[]< %s, %s", operand1, operand2);
			break;
		}
		case(OP_STD_OUT):
		{
			sprintf(instr, "\t.> %s", operand1);
			break;
		}
		case(OP_STD_OUT_ARR):
		{
			sprintf(instr, "\t.[]> %s, %s", operand1, operand2);
			break;
		}
		case(OP_ADD):
		{
			sprintf(instr, "\t+ %s, %s, %s", operand1, operand2, operand3);
			break;
		}
		case(OP_SUB):
		{
			sprintf(instr, "\t- %s, %s, %s", operand1, operand2, operand3);
			break;
		}
		case(OP_MULT):
		{
			sprintf(instr, "\t* %s, %s, %s", operand1, operand2, operand3);
			break;
		}
		case(OP_DIV):
		{
			sprintf(instr, "\t/ %s, %s, %s", operand1, operand2, operand3);
			break;
		}
		case(OP_MOD):
		{
			sprintf(instr, "\t%% %s, %s, %s", operand1, operand2, operand3);
			break;
		}
		case(OP_LT):
		{
			sprintf(instr, "\t< %s, %s, %s", operand1, operand2, operand3);
			break;
		}
		case(OP_LTE):
		{
			sprintf(instr, "\t<= %s, %s, %s", operand1, operand2, operand3);
			break;
		}
		case(OP_NEQ):
		{
			sprintf(instr, "\t!= %s, %s, %s", operand1, operand2, operand3);
			break;
		}
		case(OP_EQ):
		{
			sprintf(instr, "\t== %s, %s, %s", operand1, operand2, operand3);
			break;
		}
		case(OP_GTE):
		{
			sprintf(instr, "\t>= %s, %s, %s", operand1, operand2, operand3);
			break;
		}
		case(OP_GT):
		{
			sprintf(instr, "\t> %s, %s, %s", operand1, operand2, operand3);
			break;
		}
		case(OP_OR):
		{
			sprintf(instr, "\t|| %s, %s, %s", operand1, operand2, operand3);
			break;
		}
		case(OP_AND):
		{
			sprintf(instr, "\t&& %s, %s, %s", operand1, operand2, operand3);
			break;
		}
		case(OP_NOT):
		{
			sprintf(instr, "\t! %s, %s", operand1, operand2);
			break;
		}
		case(OP_LABEL_DEC):
		{
			sprintf(instr, ": %s", operand1);
			break;
		}
		case(OP_GOTO):
		{
			sprintf(instr, "\t:= %s", operand1);
			break;
		}
		case(OP_IF_GOTO):
		{
			sprintf(instr, "\t?:= %s, %s", operand1, operand2);
			break;
		}
		default:
		{
            cout << "Unknown Operation" << endl;
			exit(0);
			break;
		}
	}
    
    return string(instr);
}


void addInstruction(int INSTRUCTION, string operator1, string operator2, string operator3)
{
	
	string instr = generateInstruction(INSTRUCTION, operator1, operator2, operator3);
    program_vec.push_back(instr);
	return;		 
}

void newLabel(string & str)
{
    static int label_cnt = 0;
    stringstream ss;
	string tmp;
	ss << label_cnt;
	tmp = ss.str();
    str = "L" + tmp;
    ++label_cnt;
}



void newTemp(string & str)
{
    static int tmp_cnt = 0;
    stringstream ss;
	string tmp;
	ss << tmp_cnt;
	tmp = ss.str();
    str = "t" + tmp;
	symbol_table.insert(pair<string,MiniVal>(str, MiniVal('I')));
    ++tmp_cnt;
}


void newPredicate(string & str)
{
    static int pre_cnt = 0;
    stringstream ss;
	string tmp;
	ss <<  pre_cnt;
	tmp = ss.str();
    str = "p" + tmp;
	symbol_table.insert(pair<string,MiniVal>(str, MiniVal('I')));
    ++pre_cnt;
}
