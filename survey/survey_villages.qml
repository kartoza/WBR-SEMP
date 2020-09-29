<!DOCTYPE qgis PUBLIC 'http://mrcc.com/qgis.dtd' 'SYSTEM'>
<qgis simplifyLocal="1" maxScale="0" simplifyDrawingTol="1" version="3.14.0-Pi" hasScaleBasedVisibilityFlag="0" labelsEnabled="0" simplifyAlgorithm="0" simplifyDrawingHints="0" styleCategories="Symbology|Labeling|Fields|MapTips|Rendering" minScale="100000000" simplifyMaxScale="1">
  <renderer-v2 symbollevels="0" type="singleSymbol" enableorderby="0" forceraster="0">
    <symbols>
      <symbol name="0" clip_to_extent="1" type="marker" force_rhr="0" alpha="1">
        <layer class="SimpleMarker" pass="0" locked="0" enabled="1">
          <prop v="0" k="angle"/>
          <prop v="141,90,153,255" k="color"/>
          <prop v="1" k="horizontal_anchor_point"/>
          <prop v="bevel" k="joinstyle"/>
          <prop v="circle" k="name"/>
          <prop v="0,0" k="offset"/>
          <prop v="3x:0,0,0,0,0,0" k="offset_map_unit_scale"/>
          <prop v="MM" k="offset_unit"/>
          <prop v="35,35,35,255" k="outline_color"/>
          <prop v="solid" k="outline_style"/>
          <prop v="0" k="outline_width"/>
          <prop v="3x:0,0,0,0,0,0" k="outline_width_map_unit_scale"/>
          <prop v="MM" k="outline_width_unit"/>
          <prop v="diameter" k="scale_method"/>
          <prop v="2" k="size"/>
          <prop v="3x:0,0,0,0,0,0" k="size_map_unit_scale"/>
          <prop v="MM" k="size_unit"/>
          <prop v="1" k="vertical_anchor_point"/>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" value="" type="QString"/>
              <Option name="properties"/>
              <Option name="type" value="collection" type="QString"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
    </symbols>
    <rotation/>
    <sizescale/>
  </renderer-v2>
  <blendMode>0</blendMode>
  <featureBlendMode>0</featureBlendMode>
  <layerOpacity>1</layerOpacity>
  <fieldConfiguration>
    <field name="fid">
      <editWidget type="Range">
        <config>
          <Option/>
        </config>
      </editWidget>
    </field>
    <field name="name">
      <editWidget type="TextEdit">
        <config>
          <Option/>
        </config>
      </editWidget>
    </field>
    <field name="scoping_report_id">
      <editWidget type="Range">
        <config>
          <Option/>
        </config>
      </editWidget>
    </field>
  </fieldConfiguration>
  <aliases>
    <alias index="0" name="" field="fid"/>
    <alias index="1" name="" field="name"/>
    <alias index="2" name="" field="scoping_report_id"/>
  </aliases>
  <excludeAttributesWMS/>
  <excludeAttributesWFS/>
  <defaults>
    <default expression="" field="fid" applyOnUpdate="0"/>
    <default expression="" field="name" applyOnUpdate="0"/>
    <default expression="" field="scoping_report_id" applyOnUpdate="0"/>
  </defaults>
  <constraints>
    <constraint constraints="0" exp_strength="0" notnull_strength="0" unique_strength="0" field="fid"/>
    <constraint constraints="0" exp_strength="0" notnull_strength="0" unique_strength="0" field="name"/>
    <constraint constraints="0" exp_strength="0" notnull_strength="0" unique_strength="0" field="scoping_report_id"/>
  </constraints>
  <constraintExpressions>
    <constraint desc="" exp="" field="fid"/>
    <constraint desc="" exp="" field="name"/>
    <constraint desc="" exp="" field="scoping_report_id"/>
  </constraintExpressions>
  <expressionfields/>
  <mapTip></mapTip>
  <layerGeometryType>0</layerGeometryType>
</qgis>
