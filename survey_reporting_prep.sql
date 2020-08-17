--preparing survey table for reporting
set search_path to wbr_survey;

--drop view wbr_report;
create or replace view wbr_report as
select 
wbr.fid,
    --geometry,
    gt.type as gender,
    disability,
    msl.marital_status,
    acl.highest_academic_level,
    rgl.race_group,
    ab.description relation_head_household,
    esl.employment_status,
    total_income,
    same_income_monthly,
    other_source_income,
    sil.type_source_income,
    p.description main_source_water,
    ak.description use_of_water,
    at.description water_source_location,
    time_taken,
    aw.description as who_fetches_water,
    r.description method_recieve_water,
    ar.description water_shortage,
    smell_of_water,
    taste_of_water,
    b.description colour_of_water,
    m.description is_water_cleaned,
    water_bill,
    water_bill_accurate,
    ae.description sharing_water,
    aj.description toilet_facility,
    ad.description share_with_nonmembers,
    ai.description toilet_facility_location,
    am.description washing_of_hands,
    presence_of_water,
    y.description presence_of_soap,
    q.description maintain_water_source,
    c.description cook_appliance,
    ag.description stove_with_chimmney,
    ac.description room_for_cook,
    j.description heat_for_home,
    o.description light_for_home,
    f.description electronic_appliance,
    farm_animals,
    land_ownership,
    k.description hectares_land_own,
    al.description vegetable_garden,
    farmer,
    h.description farm_entity,
    g.description farm_decisions,
    n.description land_tenure_type,
    temperature_shifts,
    d.description cool_or_warm,
    aa.description rainfall_shifts,
    e.description dry_or_wet,
    x.description plant_season_shifts,
    a.description adjust_to_shifts,
    av.description weather_prediction,
    recieve_advise,
    v.description organisation_advise,
    au.description water_source_used,
    l.description irrigation_source,
    image,
    notes,
    timestamp,
    sl.surveyor,
    uuid,
    total_in_household,
    years_lived_village,
    members_employed,
    an.description water_access_improved,
    bill_water_amount,
    ao.description water_animals,
    other_disability,
    other_relationship,
    number_male_adults,
    number_female_adults,
    number_male_children,
    number_female_children,
    ax.description years_without_water,
    ap.description water_cleaning_methods,
    number_sharing_water,
    u.description number_sharing_toilet,
    w.description other_room_cook,
    other_specific_room,
    other_heating,
    other_lighting,
    total_number_animals,
    number_milk_cows,
    number_other_cattle,
    number_horse_donkey_mule,
    number_shoats,
    number_chicken_poultry,
    t.description no_garden,
    farming_years,
    other_tenure,
    other_prediction_forms,
    other_organisation_advise,
    other_irrigation_source,
    radio,
    television,
    non_mobile_telephone,
    computer,
    refrigerator,
    other_cook_appliance,
    water_observation,
    detergent_observation,
    age.age,
    crop_irrigation,
    address,
    receive_water_bill,
    i.description garden_location,
    water_for_garden,
    s.description method_watering
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
--value maps
left join adjust_to_shifts_valuemap a on wbr.adjust_to_shifts = a.id
left join colour_of_water_valuemap b on wbr.colour_of_water = b.id
left join cook_appliance_valuemap c on wbr.cook_appliance = c.id
left join cool_or_warm_valuemap d on wbr.cool_or_warm = d.id
left join dry_or_wet_valuemap e on wbr.dry_or_wet = e.id
left join electronic_appliance_valuemap f on wbr.electronic_appliance = f.id
left join farm_decisions_valuemap g on wbr.farm_decisions = g.id
left join farm_entity_valuemap h on wbr.farm_entity = h.id
left join garden_location_valuemap i on wbr.garden_location = i.id
left join heat_for_home_valuemap j on wbr.heat_for_home = j.id
left join hectares_land_own_valuemap k on wbr.hectares_land_own = k.id
left join irrigation_source_valuemap l on wbr.irrigation_source = l.id
left join is_water_cleaned_valuemap m on wbr.is_water_cleaned = m.id
left join land_tenure_type_valuemap n on wbr.land_tenure_type = n.id
left join light_for_home_valuemap o on wbr.light_for_home = o.id
left join main_source_water_valuemap p on wbr.main_source_water = p.id
left join maintain_water_source_valuemap q on wbr.maintain_water_source = q.id
left join method_recieve_water_valuemap r on wbr.method_recieve_water = r.id
left join method_watering_valuemap s on wbr.method_watering = s.id
left join no_garden_valuemap t on wbr.no_garden = t.id
left join number_sharing_toilet_valuemap u on wbr.number_sharing_toilet = u.id
left join organisation_advise_valuemap v on wbr.organisation_advise = v.id
left join other_room_cook_valuemap w on wbr.other_room_cook = w.id
left join plant_season_shifts_valuemap x on wbr.plant_season_shifts = x.id
left join presence_of_soap_valuemap y on wbr.presence_of_soap = y.id
--left join presence_of_water_valuemap z on wbr.presence_of_water = z.id
left join rainfall_shifts_valuemap aa on wbr.rainfall_shifts = aa.id
left join relation_head_household_valuemap ab on wbr.relation_head_household = ab.id
left join room_for_cook_valuemap ac on wbr.room_for_cook = ac.id
left join share_with_nonmembers_valuemap ad on wbr.share_with_nonmembers = ad.id
left join sharing_water_valuemap ae on wbr.sharing_water = ae.id
--left join smell_of_water_valuemap af on wbr.smell_of_water = af.id
left join stove_with_chimmney_valuemap ag on wbr.stove_with_chimmney = ag.id
--left join taste_of_water_valuemap ah on wbr.taste_of_water = ah.id
left join toilet_facility_location_valuemap ai on wbr.toilet_facility_location = ai.id
left join toilet_facility_valuemap aj on wbr.toilet_facility = aj.id
left join use_of_water_valuemap ak on wbr.use_of_water = ak.id
left join vegetable_garden_valuemap al on wbr.vegetable_garden = al.id
left join washing_of_hands_valuemap am on wbr.washing_of_hands = am.id
left join water_access_improved_valuemap an on wbr.water_access_improved = an.id
left join water_animals_valuemap ao on wbr.water_animals = ao.id
left join water_cleaning_methods_valuemap ap on wbr.water_cleaning_methods = ap.id
--left join water_for_garden_valuemap aq on wbr.water_for_garden = aq.id
left join water_shortage_valuemap ar on wbr.water_shortage = ar.id
left join water_source_location_valuemap at on wbr.water_source_location = at.id
left join water_source_used_valuemap au on wbr.water_source_used = au.id
left join weather_prediction_valuemap av on wbr.weather_prediction = av.id
left join who_fetches_water_valuemap aw on wbr.who_fetches_water = aw.id
left join years_without_water_valuemap ax on wbr.years_without_water = ax.id
;
	
	