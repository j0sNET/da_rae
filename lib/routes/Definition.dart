import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

import 'package:rae_scraper/rae_scraper.dart';

import '../i18n.dart';
import '../extra/unicorndial.dart';
import '../db/StoredDefinition.dart';
import '../db/DbHandler.dart';
import '../widgets/SearchBar.dart';
import '../utils.dart' as utils;
import '../widgets/DrawerContent.dart';

class Definition extends StatefulWidget {

    Definition ({Key key}) : super(key: key);

    @override
    DefinitionState createState () => DefinitionState ();
}


class DefinitionState extends State<Definition> {

    /// Indica si esta palabra está guardada en disco
    bool _saved;

    /// Clave usada para almacenar esta entrada (si es que está en disco).
    String _searchTerm;

    ///
    /// Crea los elementos necesarios para mostrar por pantalla un elemento [Acepc] que
    /// conste de un enlace.
    ///
    Widget _createLink (Acepc info, BuildContext ctx) {

        List<TextSpan> words = [ ];

        for (Palabra word in info.palabras) {
            words.add (
                utils.selectableWord (
                    word,
                    ctx,
                    actionText: "Buscar expresión '%s'".i18n.fill ([word.texto])
                )
            );
        }

        return Container (
            width: double.infinity,
            child: Card (
                color: Theme.of (ctx).highlightColor,
                margin: const EdgeInsets.all (5.0),
                child: Padding (
                    padding: const EdgeInsets.all (15.0),
                    child: SelectableText.rich (
                        TextSpan (children: words)
                    ),
                )
            )
        );
    }

    ///
    /// Crea los elementos necesarios para mostrar un elemento [Acepc] por pantalla.
    ///
    Widget _createAcepc (Acepc info, BuildContext ctx) {

        List<TextSpan> words = [
            TextSpan (
                text: "${info.num_acep}.  ",
                style: TextStyle (fontWeight: FontWeight.bold)
            )
        ];

        /* Uso -> se pone la abreviatura y, si se pulsa, se muestra el texto completo */
        if (info.uso.isNotEmpty) {

            for (Uso u in info.uso) {

                String fullText = u.significado.join (", ").capitalize ();
                words.add (
                    TextSpan (
                        text: "${u.abrev} ",
                        /* Si se pincha sobre la abreviatura, se muestra su explicación */
                        recognizer: TapGestureRecognizer ()..onTap = () =>
                            showModalBottomSheet (
                                context: ctx,
                                builder: (BuildContext ctx) => Container (
                                    padding: const EdgeInsets.all (20.0),
                                    child: Row (
                                        children: <Widget> [
                                            Expanded (child: Text ("$fullText")),
                                            CloseButton ()
                                        ]
                                    )
                                )
                            ),
                        style: TextStyle (
                            color: Theme.of (ctx).accentColor
                        )
                    )
                );
            }
        }

        for (Palabra word in info.palabras) {

            /* Igual que con el uso, si es una abreviatura se debe pinchar para mostrar
            su texto completo */
            if (word.abbr != null) {

                 words.add (
                    TextSpan (
                        text: "${word.abbr} ",
                        /* Si se pincha sobre la abreviatura, se muestra su explicación */
                        recognizer: TapGestureRecognizer ()..onTap = () =>
                            showModalBottomSheet (
                                context: ctx,
                                builder: (BuildContext ctx) => Container (
                                    padding: const EdgeInsets.all (20.0),
                                    child: Row (
                                        children: <Widget> [
                                            Expanded (child: Text ("${word.texto}")),
                                            CloseButton ()
                                        ]
                                    )
                                )
                            ),
                        style: TextStyle (
                            color: Theme.of (ctx).accentColor
                        )
                    )
                );

            } else {

                words.add (utils.selectableWord (word, ctx));
            }
        }

        return Container (
            width: double.infinity,
            child: Card (
                color: Theme.of (ctx).highlightColor,
                margin: const EdgeInsets.all (5.0),
                child: Padding (
                    padding: const EdgeInsets.all (15.0),
                    child: SelectableText.rich (
                        TextSpan (children: words)
                    ),
                )
            )
        );
    }


    ///
    /// Crea los elementos necesarios para mostrar un elemento [Expr] por pantalla.
    ///
    Widget _createExpr (Expr info, BuildContext ctx) {

        List<Widget> entries = [
            Padding (
                padding: const EdgeInsets.symmetric (vertical: 5),
                child: Text (
                    "${info.texto}",
                    style: TextStyle (fontStyle: FontStyle.italic)
                )
            )
        ];


        for (Acepc def in info.definiciones) {

            entries.add (this._createAcepc (def, ctx));
        }

        return Container (
            width: double.infinity,
            child: Card (
                color: Theme.of (ctx).highlightColor,
                margin: const EdgeInsets.all (5.0),
                child: Column (
                    children: entries
                )
            )
        );
    }




    ///
    /// Obtiene las entradas correspondientes a la definición de la palabra especificada
    ///
    List<Widget> _getEntries (Future<Resultado> definition) => <Widget>[
        Padding (
            padding: const EdgeInsets.all (5.0),
            child: FutureBuilder <Resultado>(
                future: definition
                /* Manejador para añadir el resultado cuando esté disponible */
                , builder: (BuildContext ctx, AsyncSnapshot<Resultado> snapshot) {

                    List<Widget> children = [];

                    if (snapshot.hasData) {
                        /* Los datos ya están disponibles. Primero se inicia el guardado
                        en el historial. Como es una operación asíncrona y no importa su
                        resultado (se da por hecho que siempre se inserta con éxito), se
                        lanza y no se espera a que termine. */
                        DbHandler.addToHistory (snapshot.data.palabra.texto);

                        for (Entrada e in snapshot.data.entradas) {

                            List<Widget> defs = <Widget>[];

                            /* Añade el título y la etimología como cabeceras */
                            defs.add (
                                Padding (
                                    padding: const EdgeInsets.all (5),
                                    child: Text ("${e.title}")
                                )
                            );
                            defs.add (
                                Container (
                                    /* Evita que se quede centrado, sino que se muestra
                                    al principio de la línea */
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric (
                                            vertical: 5,
                                            horizontal: 10
                                    ),
                                    child: Text (
                                        "${e.etim}",
                                        textAlign: TextAlign.start,
                                        style: TextStyle (fontStyle: FontStyle.italic)
                                    )
                                )
                            );

                            /* Añade todas las definiciones pertenecientes a esta
                               entrada */
                            for (Definic d in e.definiciones) {

                                switch (d.clase) {

                                    case ClaseAcepc.manual:
                                    case ClaseAcepc.normal:
                                        Acepc acepc = (d as Acepc);
                                        defs.add (
                                            this._createAcepc (acepc, ctx)
                                        );
                                        break;

                                    case ClaseAcepc.frase_hecha:
                                        Expr expr = (d as Expr);
                                        defs.add (
                                            this._createExpr (expr, ctx)
                                        );
                                        break;

                                    case ClaseAcepc.enlace:
                                        Acepc acepc = (d as Acepc);
                                        defs.add (
                                            this._createLink (acepc, ctx)
                                        );

                                        break;

                                    default:
                                        defs.add (
                                            Card (
                                                color: Theme.of (ctx).highlightColor,
                                                margin: const EdgeInsets.all (5.0),
                                                child: Text ("-> ${d.toString ()}\n")
                                            )
                                       );
                                }
                            }

                            defs.add (Divider ());
                            Container dictEntry = Container (
//                                color: Theme.of (ctx).highlightColor,
                                margin: const EdgeInsets.all (5.0),
                                child: Column (children: defs)
                            );

                            children.add (dictEntry);
                        }

                    } else if (snapshot.hasError) {
                        /* Hubo un error */
                        children = <Widget>[
                            Icon (
                                Icons.error_outline,
                                color: Colors.red,
                                size: 60,
                            ),
                            Padding (
                                padding: const EdgeInsets.only (top: 16.0),
                                child: Text ("Error: %s".i18n.fill ([snapshot.error])),
                            )
                        ];

                    } else {


                        if (snapshot.connectionState == ConnectionState.done) {
                            /* Terminó de cargar, pero no tiene datos (devolvió null) */
                            children = <Widget>[
                                Icon (
                                    Icons.error_outline,
                                    color: Colors.red,
                                    size: 60,
                                ),
                                Padding (
                                    padding: const EdgeInsets.only (top: 16.0),
                                    child: Text ("Palabra no encontrada :(".i18n),
                                )
                            ];

                        } else {
                            /* En espera de los datos => circulito de "cargando..." */
                            children = <Widget>[
                                SizedBox (
                                    child: CircularProgressIndicator (),
                                    width: 60,
                                    height: 60,
                                ),
                                const Padding (
                                    padding: EdgeInsets.only (top: 16.0),
                                    child: Text ("Buscando..."),
                                )
                            ];
                        }

                    }

                    /* Añade un espacio en blanco para que los botones de acciones no
                    se superpongan a las definiciones */
                    children.add (Container (height: 100));

                    return Center (
                        child: Column (
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: children
                        )
                    );
                }
            )
        )
    ];


    ///
    /// Guarda (o borra) la entrada actual del almacenamiento local.
    ///
    Future<void> _changeSaved (Future<Resultado> res) async {

        bool success;

        if (_saved) {

            /* Elimina la entrada */
            success = await DbHandler.deleteDefinition (_searchTerm);


        } else {

            Resultado r = await res;

            /* Guarda la entrada */
            DbHandler.saveDefinition (
                    StoredDefinition (searchTerm: _searchTerm, result: r)
            );
            success = true;
        }

        /* Actualiza el estado para que se dibuje el nuevo valor del icono (si es que se
        ha completado con éxito) */
        setState ( () { _saved = (success)? !_saved : _saved; } );
    }


    @override
    Widget build (BuildContext ctx) {

        Map<String, dynamic> args = ModalRoute.of (ctx).settings.arguments;

        Future<Resultado> def = args ["result"];
        /* Es posible que _saved haya cambiado como consecuencia de un [setState()] */
        if (_saved == null) {

            _saved = args ["saved"];
            _searchTerm = args ["searchTerm"];
        }

        return Scaffold (
            appBar: SearchBar (),
            /* Se usa drawer o endDrawer en función de la configuración */
            drawer: utils.settingsIsEndDrawer ()? null : DrawerContent (),
            endDrawer: utils.settingsIsEndDrawer ()? DrawerContent () : null,
            body: Container (
                child: Center (
                    child: ListView (
                        children: _getEntries (def)
                    )
                )
            ),
            floatingActionButton: UnicornDialer (
                orientation: UnicornOrientation.VERTICAL,
                parentButton: Icon (Icons.dehaze),
                childButtons: <UnicornButton>[
                    UnicornButton (
                        hasLabel: true,
                        labelText: "Volver al inicio".i18n,
                        currentButton: FloatingActionButton (
                            heroTag: null,
                            mini: true,
                            child: Icon (Icons.home),
                            onPressed: () => Navigator.of (ctx).popUntil (
                                ModalRoute.withName ("/")
                            )
                        )
                    ),
                    UnicornButton (
                        hasLabel: true,
                        labelText: (_saved?
                            "Quitar de 'palabras guardadas'"
                            : "Añadir a 'palabras guardadas'".i18n
                        ),
                        currentButton: FloatingActionButton (
                            heroTag: null,
                            mini: true,
                            child: Icon (
                                _saved? Icons.favorite
                                        : Icons.favorite_border
                            ),
                            onPressed: () => this._changeSaved (def)
                        )
                    ),
                ]
            )
        );
    }
}