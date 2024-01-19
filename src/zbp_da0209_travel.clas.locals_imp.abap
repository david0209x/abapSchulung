CLASS lhc_Travel DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR Travel RESULT result.

    METHODS ShowTestMessage FOR MODIFY
      IMPORTING keys FOR ACTION Travel~ShowTestMessage.

    METHODS ValidateAgency FOR VALIDATE ON SAVE
      IMPORTING keys FOR Travel~ValidateAgency.

    METHODS ValidateCustomer FOR VALIDATE ON SAVE
      IMPORTING keys FOR Travel~ValidateCustomer.

    METHODS ValidateDates FOR VALIDATE ON SAVE
      IMPORTING keys FOR Travel~ValidateDates.

    METHODS determinestatus FOR DETERMINE ON MODIFY
      IMPORTING keys FOR travel~determinestatus.

    METHODS determinetravelid FOR DETERMINE ON MODIFY
      IMPORTING keys FOR travel~determinetravelid.

    METHODS canceltravel FOR MODIFY
      IMPORTING keys FOR ACTION travel~canceltravel RESULT result.

ENDCLASS.

CLASS lhc_Travel IMPLEMENTATION.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD showtestmessage.
    DATA message TYPE REF TO zcm_travel.

    message = NEW zcm_travel( severity  = if_abap_behv_message=>severity-success
                              textid    = zcm_travel=>test_message
                              user_name = sy-uname ).

    APPEND message TO reported-%other.
  ENDMETHOD.

  METHOD validateagency.
    DATA message TYPE REF TO zcm_travel.

    " Read Travels
    READ ENTITY IN LOCAL MODE ZI_FE_TRAVEL_001292
         FIELDS ( AgencyId )
         WITH CORRESPONDING #( keys )
         RESULT DATA(travels).

    " Process Travels
    LOOP AT travels INTO DATA(travel).
      " Validate Agency and Create Error Message
      SELECT SINGLE FROM /dmo/agency FIELDS @abap_true WHERE agency_id = @travel-AgencyId INTO @DATA(exists).
      IF exists = abap_false.
        message = NEW zcm_travel( textid    = zcm_travel=>no_agency_found
                                  agency_id = travel-AgencyId ).
        APPEND VALUE #( %tky     = travel-%tky
                        %element = VALUE #( AgencyId = if_abap_behv=>mk-on )
                        %msg     = message ) TO reported-travel.
        APPEND VALUE #( %tky = travel-%tky ) TO failed-travel.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD validatecustomer.
    DATA message TYPE REF TO zcm_travel.

    " Read Travels
    READ ENTITY IN LOCAL MODE ZI_FE_TRAVEL_001292
         FIELDS ( CustomerId )
         WITH CORRESPONDING #( keys )
         RESULT DATA(travels).

    " Process Travels
    LOOP AT travels INTO DATA(travel).
      " Validate Agency and Create Error Message
      SELECT SINGLE FROM /dmo/customer FIELDS @abap_true WHERE customer_id = @travel-CustomerId INTO @DATA(exists).
      IF exists = abap_false.
        message = NEW zcm_travel( textid      = zcm_travel=>no_customer_found
                                  customer_id = travel-CustomerId ).
        APPEND VALUE #( %tky     = travel-%tky
                        %element = VALUE #( CustomerId = if_abap_behv=>mk-on )
                        %msg     = message ) TO reported-travel.
        APPEND VALUE #( %tky = travel-%tky ) TO failed-travel.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD validatedates.
    DATA message TYPE REF TO zcm_travel.

    " Read Travels
    READ ENTITY IN LOCAL MODE ZI_FE_TRAVEL_001292
         FIELDS ( BeginDate EndDate )
         WITH CORRESPONDING #( keys )
         RESULT DATA(travels).

    " Process Travels
    LOOP AT travels INTO DATA(travel).
      " Validate Dates and Create Error Message
      IF travel-EndDate < travel-BeginDate.
        message = NEW zcm_travel( textid = zcm_travel=>invalid_dates ).
        APPEND VALUE #( %tky = travel-%tky
                        %msg = message ) TO reported-travel.
        APPEND VALUE #( %tky = travel-%tky ) TO failed-travel.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD determinestatus.
    " Read Travels
    READ ENTITY IN LOCAL MODE ZI_FE_TRAVEL_001292
         FIELDS ( Status )
         WITH CORRESPONDING #( keys )
         RESULT DATA(travels).

    " Modify Travels
    MODIFY ENTITY IN LOCAL MODE ZI_FE_TRAVEL_001292
           UPDATE FIELDS ( Status )
           WITH VALUE #( FOR t IN travels
                         ( %tky   = t-%tky
                           Status = 'N' ) ).
  ENDMETHOD.

  METHOD determinetravelid.
    " Read Travels
    READ ENTITY IN LOCAL MODE ZI_FE_TRAVEL_001292
         FIELDS ( TravelId )
         WITH CORRESPONDING #( keys )
         RESULT DATA(travels).

    " Process Travels
    LOOP AT travels REFERENCE INTO DATA(travel).
      " Get Max Travel ID
      SELECT FROM /dmo/travel FIELDS MAX( travel_id ) INTO @DATA(max_travel_id).

      " Set Travel ID
      travel->TravelId = max_travel_id + 1.
    ENDLOOP.

    " Modify Travels
    MODIFY ENTITY IN LOCAL MODE ZI_FE_TRAVEL_001292
           UPDATE FIELDS ( TravelId )
           WITH VALUE #( FOR t IN travels
                         ( %tky     = t-%tky
                           TravelId = t-TravelId ) ).
  ENDMETHOD.
  METHOD canceltravel.
    DATA message TYPE REF TO zcm_da0209_travel.

    " Read Travels
    READ ENTITY IN LOCAL MODE ZI_FE_TRAVEL_001292
         ALL FIELDS
         WITH CORRESPONDING #( keys )
         RESULT DATA(travels).

    " Process Travels
    LOOP AT travels REFERENCE INTO DATA(travel).
      " Validate Status and Create Error Message
      IF travel->Status = 'X'.
        message = NEW zcm_da0209_travel( textid = zcm_travel=>travel_already_cancelled
                                   ).
        APPEND VALUE #( %tky     = travel->%tky
                        %element = VALUE #( Status = if_abap_behv=>mk-on )
                        %msg     = message ) TO reported-travel.
        APPEND VALUE #( %tky = travel->%tky ) TO failed-travel.
        DELETE travels INDEX sy-tabix.
        CONTINUE.
      ENDIF.

      " Set Status to Cancelled and Create Success Message
      travel->Status = 'X'.
      message = NEW zcm_da0209_travel( severity = if_abap_behv_message=>severity-success
                                textid   = zcm_travel=>travel_cancelled_successfully
                                ).
      APPEND VALUE #( %tky     = travel->%tky
                      %element = VALUE #( Status = if_abap_behv=>mk-on )
                      %msg     = message ) TO reported-travel.
    ENDLOOP.

    " Modify Travels
    MODIFY ENTITY IN LOCAL MODE ZI_FE_TRAVEL_001292
           UPDATE FIELDS ( Status )
           WITH VALUE #( FOR t IN travels
                         ( %tky = t-%tky Status = t-Status ) ).

    " Set Result
    result = VALUE #( FOR t IN travels
                      ( %tky   = t-%tky
                        %param = t ) ).
  ENDMETHOD.
ENDCLASS.
