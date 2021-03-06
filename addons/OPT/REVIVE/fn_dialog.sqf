/**
* Description:
* Dialogsteuerung 
*
* Author:
* Lord-MDB
*
* Arguments:
* None
*
* Return Value:
* None
*
* Server only:
* No
*
* Public:
* No 
* 
* Global:
* No
* 
* API:
* No
*
* Example:
* [] call FUNC(dialog);
*/
#include "macros.hpp"

if (!(isNull (findDisplay 5000 displayCtrl 5001))) exitWith{};

//Dialog erstellen
private _success = createDialog "opt_revive_blackscreen"; 

//Dialog definieren
#define IDD_REVIVE_BLACKSCREEN 5000
#define IDC_REVIVE_BUTTON 5011
#define IDC_REVIVE_MEDICNEARLABEL 5012
#define IDC_REVIVE_MEDICNEARLABEL_METER 5013
#define IDC_REVIVE_BLEEDOUTBAR 5014
#define IDC_REVIVE_BLEEDOUTBAR_TEXT 5015

private _display = findDisplay IDD_REVIVE_BLACKSCREEN;
private _BleedoutBar = _display displayCtrl IDC_REVIVE_BLEEDOUTBAR;
private _Respawn_button = _display displayCtrl IDC_REVIVE_BUTTON;
private _MedicNearLabel_Meter = _display displayCtrl IDC_REVIVE_MEDICNEARLABEL_METER;
private _BleedoutBar_Text = _display displayCtrl IDC_REVIVE_BLEEDOUTBAR_TEXT;

//Grundstellung
_BleedoutBar progressSetPosition 1.0; 
_MedicNearLabel_Meter ctrlSetText "";  
_BleedoutBar_Text ctrlSetText format ["%1 sec",GVAR(ausblutzeit)]; 

//Chat abschalten
1 enableChannel false;

// Respwan Button
_Respawn_button ctrlAddEventHandler [ "ButtonClick", 
{
	player setDamage 1;
	1 enableChannel true;
	player allowDamage true;
	
}];

GVAR(startzeit) = time;

//Anzeigen Steuerung im Dialog
[{

	params ["_args", "_handle"];

	private _display = findDisplay IDD_REVIVE_BLACKSCREEN;
	private _BleedoutBar = _display displayCtrl IDC_REVIVE_BLEEDOUTBAR;
	private _Respawn_button = _display displayCtrl IDC_REVIVE_BUTTON;
	private _MedicNearLabel_Meter = _display displayCtrl IDC_REVIVE_MEDICNEARLABEL_METER;
	private _BleedoutBar_Text = _display displayCtrl IDC_REVIVE_BLEEDOUTBAR_TEXT;

	private _dist = GVAR(sanidist);
	private _units = nearestObjects [getpos player, ["CAManBase"], _dist] - [player];
	private _medics = [];
	private _hintMsg = "";	
		
	// Sanis im Bereich finden
	if (count _units > 0) then 
	{
		_units apply 
		{
			if ((side _x isEqualTo side player) and (typeOf _x in GVAR(SaniKlassen)) and !(_x getVariable "ACE_isUnconscious")) then 
			{
				_medics pushBack _x;
			};
		};
		_medics = _medics apply { [_x distance player, _x] };
	};

	//Ordnung nächster Sani
	private _next_Medic = objNull;

	if (count _medics > 0) then 
	{
		
		_next_Medic = (_medics select 0 select 1);

		if (!isNull _next_Medic)  then 
		{
			private _medic_Name	= name _next_Medic;	
			private _abst = floor (_medics select 0 select 0);
			_hintMsg = format[MLOC(MEDIC_DISTANCE), _medic_Name, _abst];
		};
	} 
	else 
	{
		_hintMsg = MLOC(NO_MEDIC);
	};


	// Textausgabe über MEdic entfernung
	_MedicNearLabel_Meter ctrlSetText format ["%1",_hintMsg]; 

	// 3.0 ist bei ACE Medic die untergrenze für die Respwan Auslösung. 
	private _blutlevel = player getVariable ["ace_medical_bloodVolume", 6];

	//Kontrolle des nicht unterschreiten der Blutuntergrenze
	if (_blutlevel < GVAR(Blutuntergrenze)) then 
	{
		player setVariable ["ace_medical_bloodVolume", 3.5];
	};	

	//Auto Respwan nach Ablauf der Ausblutzeit
	if (((GVAR(ausblutzeit) - (time - GVAR(startzeit))) < 0) and (player getVariable ["OPT_isStabilized", 1] == 0)) then 
	{
		player setDamage 1;

	};	

	// Zeitausgabe bis Auto Respwan
	if (player getVariable ["OPT_isStabilized", 1] == 1) then 
	{
		_BleedoutBar_Text ctrlSetText format ["%1",MLOC(IS_STABILISED)]; 
		_BleedoutBar progressSetPosition 1.0; 
		_BleedoutBar_Text ctrlSetTextColor [0, 1, 0, 1];
		_BleedoutBar ctrlSetTextColor [0, 1, 0, 1];
	}
	else
	{
		_BleedoutBar_Text ctrlSetText format ["%1 sec",floor (GVAR(ausblutzeit) - (time - GVAR(startzeit)))]; 
		_BleedoutBar progressSetPosition ((floor (GVAR(ausblutzeit) - (time - GVAR(startzeit)))) / GVAR(ausblutzeit)); 
		_BleedoutBar_Text ctrlSetTextColor [1, 0, 0, 1];
		_BleedoutBar ctrlSetTextColor [1, 0, 0, 1];
	};

	// Check Dialog offen
	if (isNull (_display displayCtrl 5001)) then
	{
		createDialog "opt_revive_blackscreen";
	};	

	// Dialog und PFH Löschung
	if ((getDammage player) == 1)  then 
	{
		closeDialog 5000;	
		closeDialog 0;
		1 enableChannel true;
		player allowDamage true;
		OPT_REVIVE_unconsciousHandler = nil;
		player setVariable ["OPT_isUnconscious", 0, true];
		player setVariable ["OPT_isStabilized", 0, true];
		_handle call CFUNC(removePerframeHandler);
	};

	if (!(player getVariable "ACE_isUnconscious"))  then 
	{	
		closeDialog 5000;
		closeDialog 0;
		1 enableChannel true;
		player allowDamage true;
		OPT_REVIVE_unconsciousHandler = nil;
		player setVariable ["OPT_isUnconscious", 0, true];
		player setVariable ["OPT_isStabilized", 0, true];
		_handle call CFUNC(removePerframeHandler);
	};		

}, 1, _this] call CFUNC(addPerFrameHandler);

