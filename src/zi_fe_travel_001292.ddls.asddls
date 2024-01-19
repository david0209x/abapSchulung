@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'CDS View forTravel'
define root view entity ZI_FE_Travel_001292
  as select from zfe_atrav_001292
  association [0..1] to /DMO/I_Agency as _Agency on $projection.AgencyID = _Agency.AgencyID
  association [0..1] to I_Currency as _Currency on $projection.CurrencyCode = _Currency.Currency
  association [0..1] to /DMO/I_Customer as _Customer on $projection.CustomerID = _Customer.CustomerID
  association [0..1] to zi_fe_stat_001292 as _TravelStatus on $projection.OverallStatus = _TravelStatus.TravelStatusId
  //composition [0..*] of ZI_FE_Booking_001292 as _Booking
  composition [0..*] of ZI_FE_Booking_001292 as _Booking
  association [1..1] to /DMO/I_Customer as _CustomerText on $projection.CustomerID = _CustomerText.CustomerID
{
  key travel_uuid as TravelUUID,
  travel_id as TravelID,
  agency_id as AgencyID,
  customer_id as CustomerID,
  begin_date as BeginDate,
  end_date as EndDate,
  @Semantics.amount.currencyCode: 'CurrencyCode'
  booking_fee as BookingFee,
  @Semantics.amount.currencyCode: 'CurrencyCode'
  total_price as TotalPrice,
  currency_code as CurrencyCode,
  description as Description,
  overall_status as OverallStatus,
  @Semantics.user.createdBy: true
  created_by as CreatedBy,
  @Semantics.systemDateTime.createdAt: true
  created_at as CreatedAt,
  @Semantics.user.lastChangedBy: true
  last_changed_by as LastChangedBy,
  @Semantics.systemDateTime.lastChangedAt: true
  last_changed_at as LastChangedAt,
  @Semantics.systemDateTime.localInstanceLastChangedAt: true
  local_last_changed_at as LocalLastChangedAt,
  overall_status as Status,
  
  /* Transient Data */
      _CustomerText.CustomerID as CustomerName,
      case when dats_days_between($session.user_date, begin_date) >= 14 then 3
           when dats_days_between($session.user_date, begin_date) >= 7 then 2
           when dats_days_between($session.user_date, begin_date) >= 0 then 1
           else 0
      end                as BeginDateCriticality,
      case overall_status when 'B' then 3
                  when 'N' then 0
                  when 'X' then 1
                  else 0
      end                as StatusCriticality,
  
  _Booking,
  _Agency,
  _Currency,
  _Customer,
  _TravelStatus
}
