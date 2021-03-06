import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:i18n_extension/i18n_widget.dart';
import 'package:preferences/preferences.dart';

import '../i18n.dart';
import '../utils.dart';
import '../widgets/DrawerContent.dart';

class Settings extends StatelessWidget {

    final _log = Logger ("Settings.dart");


    /// Cambia la configuración de idioma por el nuevo seleccionado ([newLang])
    void _changeLang (BuildContext ctx, String newLang) {

        Locale newLocale;
        /* Cambia el idioma a uno de los implementados (por defecto, inglés) */
        switch (newLang) {

            case "Español":
                newLocale = Locale ("es");
                break;

            case "English":
            default:
                newLocale = Locale ("en");
        }

        _log.fine ("New locale: $newLocale");

        I18n.of (ctx).locale = newLocale;
    }


    /// Obtiene el idioma configurado en el sistema
    String _getDefaultLocale (BuildContext ctx) {

        String langCode = Localizations.localeOf (ctx).languageCode;

        _log.fine ("System's default lang code: '$langCode'");

        /* Si el idioma del sistema no está soportado, usa inglés por defecto */
        switch (langCode) {

            case "es":
                _log.fine ("Set 'Español' as the language code");
                return "Español";

            case "en":
            default:
                _log.fine ("Set 'English' as the language code");
                return "English";
        }
    }


    @override
    Widget build (BuildContext ctx) => Scaffold (
        appBar: AppBar (title: Text ("Configuración".i18n)),
        /* Se usa drawer o endDrawer en función de la configuración */
        drawer: settingsIsEndDrawer ()? null : DrawerContent (),
        endDrawer: settingsIsEndDrawer ()? DrawerContent () : null,
        body: PreferencePage ([
            /* Sección general para cambiar el tema, el idioma... */
            PreferenceTitle ("General".i18n),
            DropdownPreference (
                "Idioma".i18n,
                "lang",
                defaultVal: _getDefaultLocale (ctx),
                values: [
                    /* Estas cadenas no se traducen para que todo el mundo pueda
                    encontrar su idioma preferido fácilmente */
                    "Español",
                    "English"
                ],
                onChange: (String selected) => _changeLang (ctx, selected)
            ),
            DropdownPreference (
                "Tema".i18n,
                "ui_theme",
                defaultVal: DEFAULT_THEME,
                values: [
                    "Dark",
                    "Bright"
                ],
                onChange: (_) => showDialog (
                    context: ctx,
                    builder: (BuildContext ctx) => AlertDialog (
                        content: Text ("Reinicia la aplicación para que se cargue el nuevo tema".i18n),
                    )
                )
            ),
            SwitchPreference (
                "Menú desplegable a la derecha".i18n,
                "end_drawer",
                defaultVal: DEFAULT_END_DRAWER,
            ),
            /* Sección para los límites de tamaño/peticiones/... */
            PreferenceTitle ("Límites".i18n),
            DropdownPreference (
                "Nivel de detalle en el log".i18n,
                "log_level",
                defaultVal: DEFAULT_LOG_LEVEL,
                values: [
                    "ALL",
                    "CONFIG",
                    "FINE",
                    "FINER",
                    "FINEST",
                    "INFO",
                    "OFF",
                    "SEVERE",
                    "SHOUT",
                    "WARNING"
                ],
                onChange: setLogLevel
            ),
            DropdownPreference (
                "Tamaño máximo del historial".i18n,
                "max_hist_size",
                defaultVal: DEFAULT_HIST_SIZE,
                /* Genera una lista entre el 0 y el 50 */
                values: List.generate (50, (i) => i),
                onChange: setHistSize
            ),
            DropdownPreference (
                "Tamaño máximo de la caché".i18n,
                "max_cache_size",
                defaultVal: DEFAULT_CACHE_SIZE,
                /* Genera una lista entre el 50 y el 200 */
                values: List.generate (200, (i) => i + 50),
                onChange: setCacheSize
            )
        ])
    );

}
