class ZCL_SINGLETON_FACTORY definition
  public
  final
  create public .

public section.

  class-methods CLASS_CONSTRUCTOR .
  class-methods GET
    importing
      !IV_FUNC type RS38L_FNAM
      !IT_ARGUMENT type STRING_TABLE
    returning
      value(RV_CURRIED_FUNC) type RS38L_FNAM .
  class-methods CLEANUP .
  PROTECTED SECTION.
private section.

  types:
    BEGIN OF ty_curried_func,
        func_name      TYPE rs38l_fnam,
        curried_func   TYPE rs38l_fnam,
        function_group TYPE rs38l-area,
      END OF ty_curried_func .
  types:
    tt_curried_func TYPE TABLE OF ty_curried_func WITH KEY func_name curried_func .
  types:
    begin of ty_fm_argument_line,
              parameter type FUPARAREF-parameter,
              param_type type FUPARAREF-paramtype,
              structure type FUPARAREF-structure,
         end of ty_fm_argument_line .
  types:
    tt_fm_argument TYPe STANDARD TABLE OF ty_fm_argument_line with key parameter .
  types:
    begin of ty_fm_argument,
             func_name type FUPARAREF-funcname,
             func_arg type tt_fm_argument,
          end of ty_fm_argument .
  types:
    tt_fm_argument_detail type STANDARD TABLE OF ty_fm_Argument with key func_name .

  "TYPES: TT_fm_ARGUMENT TYPE TABLE OF FUPARAREF WITH KEY funcname parameter.
  data MT_CURRIED_FUNC type TT_CURRIED_FUNC .
  data MV_ORG_FUNC type RS38L_FNAM .
  class-data SO_INSTANCE type ref to ZCL_SINGLETON_FACTORY .
  data MV_CURRIED type RS38L_FNAM .
  data MT_FM_ARGUMENT type TT_FM_ARGUMENT_DETAIL .

  methods ADAPT_SOURCE_CODE
    importing
      !IV_INCLUDE type PROGNAME .
  methods RUN
    importing
      !IV_FUNC type RS38L_FNAM
      !IT_ARGUMENT type STRING_TABLE
    returning
      value(RV_CURRIED_FUNC) type RS38L_FNAM .
  methods PARSE_ARGUMENT .
  methods GENERATE_SINGLETON_FM
    returning
      value(RV_GENERATED_INCLUDE) type PROGNAME .
  methods _CLEANUP .
ENDCLASS.



CLASS ZCL_SINGLETON_FACTORY IMPLEMENTATION.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Private Method ZCL_SINGLETON_FACTORY->ADAPT_SOURCE_CODE
* +-------------------------------------------------------------------------------------------------+
* | [--->] IV_INCLUDE                     TYPE        PROGNAME
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD ADAPT_SOURCE_CODE.
*    DATA:lt_codeline    TYPE STANDARD TABLE OF char255,
*         lv_argu        TYPE string,
*         lt_parsed_argu TYPE tt_curried_argument.
*    READ REPORT iv_include INTO lt_codeline.
*
*    DELETE lt_codeline INDEX lines( lt_codeline ).
*    DELETE lt_codeline WHERE table_line IS INITIAL.
*
*    APPEND |DATA: lt_ptab TYPE abap_func_parmbind_tab.| TO lt_codeline.
*    APPEND |DATA: ls_para LIKE LINE OF lt_ptab.| TO lt_codeline.
*    lt_parsed_argu = mt_curried_func[ func_name = mv_org_func curried_func = mv_curried ]-curried_arg.
*    LOOP AT lt_parsed_argu ASSIGNING FIELD-SYMBOL(<argu>).
*      APPEND | DATA:  _{ <argu>-arg_name } LIKE { <argu>-arg_name }.| TO lt_codeline.
*
*      IF <argu>-arg_value IS NOT INITIAL.
*        APPEND | _{ <argu>-arg_name } = '{ <argu>-arg_value }'. | TO lt_codeline.
*      ELSE.
*        APPEND | _{ <argu>-arg_name } = { <argu>-arg_name }. | TO lt_codeline.
*      ENDIF.
*
*      lv_argu = | ls_para = value #( name = '{ <argu>-arg_name }' | &&
*         | kind  = abap_func_exporting value = REF #( _{ <argu>-arg_name } ) ).|.
*      APPEND lv_argu TO lt_codeline.
*      APPEND | APPEND ls_para TO lt_ptab. | TO lt_codeline.
*    ENDLOOP.
*
*    APPEND 'TRY.' TO lt_codeline.
*    APPEND |CALL FUNCTION '{ mv_org_func }' PARAMETER-TABLE lt_ptab.| TO lt_codeline.
*    APPEND | CATCH cx_root INTO DATA(cx_root). | TO lt_codeline.
*    APPEND |WRITE: / cx_root->get_text( ).| TO lt_codeline.
*    APPEND 'ENDTRY.' TO lt_codeline.
*    APPEND 'ENDFUNCTION.' TO lt_codeline.
*    INSERT REPORT iv_include FROM lt_codeline.
*    COMMIT WORK AND WAIT.
*    WAIT UP TO 1 SECONDS.
  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Static Public Method ZCL_SINGLETON_FACTORY=>CLASS_CONSTRUCTOR
* +-------------------------------------------------------------------------------------------------+
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD CLASS_CONSTRUCTOR.
    CREATE OBJECT so_instance.
  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Static Public Method ZCL_SINGLETON_FACTORY=>CLEANUP
* +-------------------------------------------------------------------------------------------------+
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD CLEANUP.
    so_instance->_cleanup( ).
  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Private Method ZCL_SINGLETON_FACTORY->GENERATE_SINGLETON_FM
* +-------------------------------------------------------------------------------------------------+
* | [<-()] RV_GENERATED_INCLUDE           TYPE        PROGNAME
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD GENERATE_SINGLETON_FM.
    DATA: lv_date               TYPE sy-datum,
          lv_time               TYPE sy-uzeit,
          lv_pool_name          TYPE rs38l-area,
          lv_func_name          TYPE rs38l-name,
          l_function_include    TYPE progname,
          lt_exception_list     TYPE TABLE OF rsexc,
          lt_export_parameter   TYPE TABLE OF rsexp,
          lt_import_parameter   TYPE TABLE OF rsimp,
          wa_rsimp              TYPE rsimp,
          lt_tables_parameter   TYPE TABLE OF rstbl,
          lt_changing_parameter TYPE TABLE OF rscha,
          lt_parameter_docu     TYPE TABLE OF rsfdo.

    lv_date = sy-datum.
    lv_time = sy-uzeit.

    CONCATENATE 'LAZY' lv_date lv_time INTO lv_pool_name.
    CONCATENATE 'Z' lv_pool_name INTO lv_func_name.

    CALL FUNCTION 'RS_FUNCTION_POOL_INSERT'
      EXPORTING
        function_pool           = lv_pool_name
        short_text              = 'Lazy Load Function demo by Jerry'       "#EC NOTEXT
        devclass                = '$TMP'                        "#EC NOTEXT
        responsible             = sy-uname
        suppress_corr_check     = space
      EXCEPTIONS
        name_already_exists     = 1
        name_not_correct        = 2
        function_already_exists = 3
        invalid_function_pool   = 4
        invalid_name            = 5
        too_many_functions      = 6
        no_modify_permission    = 7
        no_show_permission      = 8
        enqueue_system_failure  = 9
        canceled_in_corr        = 10
        undefined_error         = 11
        OTHERS                  = 12.
    IF sy-subrc <> 0.
      WRITE:/ 'Functio group was not created: ' , sy-subrc .
      RETURN.
    ENDIF.

    READ TABLE mt_fm_argument ASSIGNING FIELD-SYMBOL(<fm_arg>) WITH KEY func_name = mv_org_func.
    CHECK sy-subrc = 0.

*    LOOP AT it_parsed_argument ASSIGNING FIELD-SYMBOL(<argu>).
*      wa_rsimp-parameter = <argu>-arg_name.                 "#EC NOTEXT
*      wa_rsimp-reference = 'X'.
*      wa_rsimp-optional = 'X'.                              "#EC NOTEXT
*      wa_rsimp-typ       = 'STRING'.                        "#EC NOTEXT
*      APPEND wa_rsimp TO lt_import_parameter.
*    ENDLOOP.
*    CALL FUNCTION 'FUNCTION_CREATE'
*      EXPORTING
*        funcname                = lv_func_name
*        function_pool           = lv_pool_name
*        short_text              = 'Lazy Load test by Jerry'                 "#EC NOTEXT
*      IMPORTING
*        function_include        = l_function_include
*      TABLES
*        exception_list          = lt_exception_list
*        export_parameter        = lt_export_parameter
*        import_parameter        = lt_import_parameter
*        tables_parameter        = lt_tables_parameter
*        changing_parameter      = lt_changing_parameter
*        parameter_docu          = lt_parameter_docu
*      EXCEPTIONS
*        double_task             = 1
*        error_message           = 2
*        function_already_exists = 3
*        invalid_function_pool   = 4
*        invalid_name            = 5
*        too_many_functions      = 6
*        OTHERS                  = 7.
*
*    IF sy-subrc <> 0.
*      WRITE: / 'failed:', sy-subrc.
*      RETURN.
*    ENDIF.
*
*    APPEND INITIAL LINE TO mt_curried_func ASSIGNING FIELD-SYMBOL(<curried_fm>).
*
*    <curried_fm>-func_name = mv_org_func.
*    mv_curried = <curried_fm>-curried_func = lv_func_name.
*    <curried_fm>-curried_arg = it_parsed_argument.
*    <curried_fm>-function_group = lv_pool_name.
*
*    rv_generated_include = l_function_include.

  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Static Public Method ZCL_SINGLETON_FACTORY=>GET
* +-------------------------------------------------------------------------------------------------+
* | [--->] IV_FUNC                        TYPE        RS38L_FNAM
* | [--->] IT_ARGUMENT                    TYPE        STRING_TABLE
* | [<-()] RV_CURRIED_FUNC                TYPE        RS38L_FNAM
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD GET.
    rv_curried_func = so_instance->run( iv_func = iv_func it_argument = it_argument ).
  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Private Method ZCL_SINGLETON_FACTORY->PARSE_ARGUMENT
* +-------------------------------------------------------------------------------------------------+
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD PARSE_ARGUMENT.
    data: lt_argu TYPE TABLE OF fupararef.
    READ TABLE mt_fm_argument WITH KEY func_name = mv_org_func TRANSPORTING NO FIELDS.
    CHECK sy-subrc <> 0.

    SELECT * INTO TABLE lt_argu FROM fupararef WHERE funcname = mv_org_func
      AND r3state = 'A'.
    CHECK sy-subrc = 0.
    APPEND INITIAL LINE TO mt_fm_argument ASSIGNING FIELD-SYMBOL(<fm_argument>).
    <fm_argument>-func_name = mv_org_func.

    LOOP AT lt_argu ASSIGNING FIELD-SYMBOL(<form_argu>).
       data(ls_fm_argu) = value ty_fm_argument_line( parameter = <form_argu>-parameter
         param_type = <form_argu>-paramtype
         structure = <form_argu>-structure ).
       APPEND ls_fm_argu TO <fm_argument>-func_arg.
    ENDLOOP.

  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Private Method ZCL_SINGLETON_FACTORY->RUN
* +-------------------------------------------------------------------------------------------------+
* | [--->] IV_FUNC                        TYPE        RS38L_FNAM
* | [--->] IT_ARGUMENT                    TYPE        STRING_TABLE
* | [<-()] RV_CURRIED_FUNC                TYPE        RS38L_FNAM
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD RUN.
    mv_org_func = iv_func.
    parse_argument( ).
    DATA(lv_include) = generate_singleton_fm( ).
    adapt_source_code( lv_include ).
    rv_curried_func = mv_curried.
  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Private Method ZCL_SINGLETON_FACTORY->_CLEANUP
* +-------------------------------------------------------------------------------------------------+
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD _CLEANUP.
    LOOP AT mt_curried_func ASSIGNING FIELD-SYMBOL(<curried>).

      CALL FUNCTION 'FUNCTION_DELETE'
        EXPORTING
          funcname = <curried>-curried_func.

      CALL FUNCTION 'FUNCTION_POOL_DELETE'
        EXPORTING
          pool = <curried>-function_group.
    ENDLOOP.

    CLEAR: mt_curried_func.
  ENDMETHOD.
ENDCLASS.