--preparing survey table for reporting
set search_path to wbr_survey,public;

--REFRESH MATERIALIZED VIEW wbr_report;

--drop materialized view wbr_report;
create materialized view wbr_report as
select 
sv.name as village_name,
wbr.fid,
    geometry,
    gt.type as gender,
    disability,
    msl.marital_status,
    acl.highest_academic_level,
    rgl.race_group,
    ae.description relation_head_household,
    esl.employment_status,
    til.total_income,
    same_income_monthly,
    other_source_income,
    sil.type_source_income,
    q.description main_source_water,
    am.description use_of_water,
    au.description water_source_location,
    time_taken,
    ax.description as who_fetches_water,
    s.description method_recieve_water,
    at.description water_shortage,
    smell_of_water,
    taste_of_water,
    b.description colour_of_water,
    n.description is_water_cleaned,
    water_bill,
    water_bill_accurate,
    ae.description sharing_water,
    al.description toilet_facility,
    ag.description share_with_nonmembers,
    ak.description toilet_facility_location,
    ao.description washing_of_hands,
    presence_of_water,
    aa.description presence_of_soap,
    r.description maintain_water_source,
    d.description cook_appliance,
    ai.description stove_with_chimmney,
    af.description room_for_cook,
    k.description heat_for_home,
    p.description light_for_home,
    g.description electronic_appliance,
    farm_animals,
    land_ownership,
    l.description hectares_land_own,
    an.description vegetable_garden,
    farmer,
    i.description farm_entity,
    h.description farm_decisions,
    o.description land_tenure_type,
    temperature_shifts,
    e.description cool_or_warm,
    ac.description rainfall_shifts,
    f.description dry_or_wet,
    z.description plant_season_shifts,
    a.description adjust_to_shifts,
    aw.description weather_prediction,
    recieve_advise,
    x.description organisation_advise,
    av.description water_source_used,
    m.description irrigation_source,
    image,
    notes,
    timestamp,
    sl.surveyor,
    uuid,
    total_in_household,
    years_lived_village,
    members_employed,
    ap.description water_access_improved,
    bill_water_amount,
    aq.description water_animals,
    other_disability,
    other_relationship,
    number_male_adults,
    number_female_adults,
    number_male_children,
    number_female_children,
    ay.description years_without_water,
    ar.description water_cleaning_methods,
    number_sharing_water,
    w.description number_sharing_toilet,
    y.description other_room_cook,
    other_specific_room,
    other_heating,
    other_lighting,
    total_number_animals,
    number_milk_cows,
    number_other_cattle,
    number_horse_donkey_mule,
    number_shoats,
    number_chicken_poultry,
    u.description no_garden,
    farming_years,
    other_tenure,
    other_prediction_forms,
    other_organisation_advise,
    other_irrigation_source,
    ab.description radio,
    aj.description television,
    v.description non_mobile_telephone,
    c.description computer,
    ad.description refrigerator,
    other_cook_appliance,
    water_observation,
    detergent_observation,
    age.age,
    crop_irrigation,
    address,
    receive_water_bill,
    j.description garden_location,
    water_for_garden,
    t.description method_watering
    --surveyor
from sync_main.wbr 
--lookups
left join sync_main.academic_level_lookup acl on wbr.highest_academic_level = acl.fid
left join sync_main.age_lookup age on wbr.age = age.fid
left join sync_main.employment_status_lookup esl on wbr.employment_status = esl.fid
left join sync_main.gender_type gt on wbr.gender = gt.fid
left join sync_main.marital_status_lookup msl on wbr.marital_status = msl.fid
left join sync_main.race_group_lookup rgl on wbr.race_group = rgl.fid
left join sync_main.source_income_lookup sil on wbr.type_source_income = sil.fid
left join sync_main.surveyor_lookup sl on wbr.edit_by::integer = sl.fid
left join sync_main.total_income_lookup til on wbr.total_income = til.fid
--value maps
left join adjust_to_shifts_valuemap a on wbr.adjust_to_shifts = a.id
left join colour_of_water_valuemap b on wbr.colour_of_water = b.id
left join computer_valuemap c on wbr.computer = c.id
left join cook_appliance_valuemap d on wbr.cook_appliance = d.id
left join cool_or_warm_valuemap e on wbr.cool_or_warm = e.id
left join dry_or_wet_valuemap f on wbr.dry_or_wet = f.id
left join electronic_appliance_valuemap g on wbr.electronic_appliance = g.id
left join farm_decisions_valuemap h on wbr.farm_decisions = h.id
left join farm_entity_valuemap i on wbr.farm_entity = i.id
left join garden_location_valuemap j on wbr.garden_location = j.id
left join heat_for_home_valuemap k on wbr.heat_for_home = k.id
left join hectares_land_own_valuemap l on wbr.hectares_land_own = l.id
left join irrigation_source_valuemap m on wbr.irrigation_source = m.id
left join is_water_cleaned_valuemap n on wbr.is_water_cleaned = n.id
left join land_tenure_type_valuemap o on wbr.land_tenure_type = o.id
left join light_for_home_valuemap p on wbr.light_for_home = p.id
left join main_source_water_valuemap q on wbr.main_source_water = q.id
left join maintain_water_source_valuemap r on wbr.maintain_water_source = r.id
left join method_recieve_water_valuemap s on wbr.method_recieve_water = s.id
left join method_watering_valuemap t on wbr.method_watering = t.id
left join no_garden_valuemap u on wbr.no_garden = u.id
left join non_mobile_telephone_valuemap v on wbr.non_mobile_telephone = v.id
left join number_sharing_toilet_valuemap w on wbr.number_sharing_toilet = w.id
left join organisation_advise_valuemap x on wbr.organisation_advise = x.id
left join other_room_cook_valuemap y on wbr.other_room_cook = y.id
left join plant_season_shifts_valuemap z on wbr.plant_season_shifts = z.id
left join presence_of_soap_valuemap aa on wbr.presence_of_soap = aa.id
left join radio_valuemap ab on wbr.radio = ab.id
left join rainfall_shifts_valuemap ac on wbr.rainfall_shifts = ac.id
left join refrigerator_valuemap ad on wbr.refrigerator = ad.id
left join relation_head_household_valuemap ae on wbr.relation_head_household = ae.id
left join room_for_cook_valuemap af on wbr.room_for_cook = af.id
left join share_with_nonmembers_valuemap ag on wbr.share_with_nonmembers = ag.id
left join sharing_water_valuemap ah on wbr.sharing_water = ah.id
left join stove_with_chimmney_valuemap ai on wbr.stove_with_chimmney = ai.id
left join television_valuemap aj on wbr.television = aj.id
left join toilet_facility_location_valuemap ak on wbr.toilet_facility_location = ak.id
left join toilet_facility_valuemap al on wbr.toilet_facility = al.id
left join use_of_water_valuemap am on wbr.use_of_water = am.id
left join vegetable_garden_valuemap an on wbr.vegetable_garden = an.id
left join washing_of_hands_valuemap ao on wbr.washing_of_hands = ao.id
left join water_access_improved_valuemap ap on wbr.water_access_improved = ap.id
left join water_animals_valuemap aq on wbr.water_animals = aq.id
left join water_cleaning_methods_valuemap ar on wbr.water_cleaning_methods = ar.id
left join water_shortage_valuemap at on wbr.water_shortage = at.id
left join water_source_location_valuemap au on wbr.water_source_location = au.id
left join water_source_used_valuemap av on wbr.water_source_used = av.id
left join weather_prediction_valuemap aw on wbr.weather_prediction = aw.id
left join who_fetches_water_valuemap ax on wbr.who_fetches_water = ax.id
left join years_without_water_valuemap ay on wbr.years_without_water = ay.id
--which village do they belong to?
left join survey_villages sv on st_within(wbr.geometry,sv.geom)
;

GRANT SELECT ON TABLE wbr_survey.wbr_report TO readonly;	