import 'package:flutter/material.dart';

/// Sincroniza una lista propia con una nueva versión llegada de un
/// provider, identificando cada elemento por [idOf], y avisa qué se
/// quitó y qué se insertó (y en qué índice) — pensado para alimentar
/// [AnimatedList]/[SliverAnimatedList] sin reconstruir toda la lista de
/// golpe en cada refresco automático (eso es lo que causaba el
/// "parpadeo": cada poll de 10s tiraba la lista entera a un spinner).
///
/// No anima reordenamientos: si un elemento que ya estaba cambia de
/// posición entre refrescos (ej. la lista de cercanas se reordena por
/// distancia al moverse el profesional), se actualiza su contenido en
/// el sitio donde ya estaba en vez de animarlo a la posición nueva — es
/// una simplificación deliberada, reordenar con animación no aporta
/// tanto como insertar/quitar y complica bastante más el diff.
class ListSyncer<T> {
  ListSyncer(List<T> inicial, this.idOf) : items = List.of(inicial);

  final String Function(T) idOf;
  final List<T> items;

  void sync(
    List<T> nuevos, {
    required void Function(int index, T item) onRemove,
    required void Function(int index) onInsert,
  }) {
    final idsViejos = items.map(idOf).toList();
    final idsNuevos = nuevos.map(idOf).toSet();

    for (var i = idsViejos.length - 1; i >= 0; i--) {
      if (!idsNuevos.contains(idsViejos[i])) {
        final item = items.removeAt(i);
        onRemove(i, item);
      }
    }

    final idsActuales = items.map(idOf).toSet();
    for (var i = 0; i < nuevos.length; i++) {
      final id = idOf(nuevos[i]);
      if (!idsActuales.contains(id)) {
        items.insert(i, nuevos[i]);
        idsActuales.add(id);
        onInsert(i);
      }
    }

    // Los que ya estaban y siguen estando: se actualiza su contenido en
    // el sitio (ej. cambió `yaPostulado`) sin mover nada ni re-animar.
    for (var i = 0; i < items.length; i++) {
      final idx = nuevos.indexWhere((n) => idOf(n) == idOf(items[i]));
      if (idx != -1) items[i] = nuevos[idx];
    }
  }
}

Widget _transicionEntrada(Animation<double> animation, Widget child) {
  return SizeTransition(
    sizeFactor: CurvedAnimation(parent: animation, curve: Curves.easeOut),
    child: FadeTransition(opacity: animation, child: child),
  );
}

const _duracionTransicion = Duration(milliseconds: 260);

/// Versión "sliver" — para usar dentro de un CustomScrollView junto a
/// otros slivers (ver home_profesional_screen.dart, que tiene un tile
/// de "trabajos activos" antes de esta lista).
class AnimatedSliverList<T> extends StatefulWidget {
  const AnimatedSliverList({
    super.key,
    required this.items,
    required this.idOf,
    required this.itemBuilder,
    this.padding = EdgeInsets.zero,
  });

  final List<T> items;
  final String Function(T) idOf;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final EdgeInsets padding;

  @override
  State<AnimatedSliverList<T>> createState() => _AnimatedSliverListState<T>();
}

class _AnimatedSliverListState<T> extends State<AnimatedSliverList<T>> {
  final _key = GlobalKey<SliverAnimatedListState>();
  late final ListSyncer<T> _syncer;

  @override
  void initState() {
    super.initState();
    _syncer = ListSyncer<T>(widget.items, widget.idOf);
  }

  @override
  void didUpdateWidget(covariant AnimatedSliverList<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncer.sync(
      widget.items,
      onRemove: (index, item) => _key.currentState?.removeItem(
        index,
        (context, animation) => _transicionEntrada(animation, widget.itemBuilder(context, item, index)),
        duration: _duracionTransicion,
      ),
      onInsert: (index) => _key.currentState?.insertItem(index, duration: _duracionTransicion),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: widget.padding,
      sliver: SliverAnimatedList(
        key: _key,
        initialItemCount: _syncer.items.length,
        itemBuilder: (context, index, animation) {
          if (index >= _syncer.items.length) return const SizedBox.shrink();
          return _transicionEntrada(animation, widget.itemBuilder(context, _syncer.items[index], index));
        },
      ),
    );
  }
}

/// Versión "plana" — para usar como cuerpo único de una pantalla, sin
/// otros slivers alrededor (ver trabajos_activos_profesional_screen.dart).
class AnimatedFlatList<T> extends StatefulWidget {
  const AnimatedFlatList({
    super.key,
    required this.items,
    required this.idOf,
    required this.itemBuilder,
    this.padding = EdgeInsets.zero,
  });

  final List<T> items;
  final String Function(T) idOf;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final EdgeInsets padding;

  @override
  State<AnimatedFlatList<T>> createState() => _AnimatedFlatListState<T>();
}

class _AnimatedFlatListState<T> extends State<AnimatedFlatList<T>> {
  final _key = GlobalKey<AnimatedListState>();
  late final ListSyncer<T> _syncer;

  @override
  void initState() {
    super.initState();
    _syncer = ListSyncer<T>(widget.items, widget.idOf);
  }

  @override
  void didUpdateWidget(covariant AnimatedFlatList<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncer.sync(
      widget.items,
      onRemove: (index, item) => _key.currentState?.removeItem(
        index,
        (context, animation) => _transicionEntrada(animation, widget.itemBuilder(context, item, index)),
        duration: _duracionTransicion,
      ),
      onInsert: (index) => _key.currentState?.insertItem(index, duration: _duracionTransicion),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedList(
      key: _key,
      padding: widget.padding,
      initialItemCount: _syncer.items.length,
      itemBuilder: (context, index, animation) {
        if (index >= _syncer.items.length) return const SizedBox.shrink();
        return _transicionEntrada(animation, widget.itemBuilder(context, _syncer.items[index], index));
      },
    );
  }
}
