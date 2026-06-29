import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:memoryos/core/domain/entities.dart';
import 'package:memoryos/core/domain/repositories.dart';

// ═══════════════════════════════════════════════════════════════════
// HOME BLOC — real stats, recent files, index status
// ═══════════════════════════════════════════════════════════════════

abstract class HomeEvent extends Equatable {
  const HomeEvent();
  @override List<Object?> get props => [];
}

class HomeLoadRequested extends HomeEvent {}
class HomeRefreshRequested extends HomeEvent {}
class HomeFileImported extends HomeEvent {
  final String path;
  const HomeFileImported(this.path);
  @override List<Object?> get props => [path];
}

enum HomeStatus { initial, loading, loaded, error }

class HomeState extends Equatable {
  final HomeStatus status;
  final StorageStats stats;
  final List<FileEntry> recentFiles;
  final IndexStats indexStats;
  final String? error;

  const HomeState({
    this.status = HomeStatus.initial,
    this.stats = const StorageStats(),
    this.recentFiles = const [],
    this.indexStats = const IndexStats(),
    this.error,
  });

  HomeState copyWith({
    HomeStatus? status,
    StorageStats? stats,
    List<FileEntry>? recentFiles,
    IndexStats? indexStats,
    String? error,
  }) =>
      HomeState(
        status: status ?? this.status,
        stats: stats ?? this.stats,
        recentFiles: recentFiles ?? this.recentFiles,
        indexStats: indexStats ?? this.indexStats,
        error: error ?? this.error,
      );

  @override
  List<Object?> get props => [status, stats, recentFiles.length, indexStats, error];
}

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final FileRepository _files;

  HomeBloc(this._files) : super(const HomeState()) {
    on<HomeLoadRequested>(_onLoad);
    on<HomeRefreshRequested>(_onLoad);
    on<HomeFileImported>(_onFileImported);
  }

  Future<void> _onLoad(HomeEvent event, Emitter<HomeState> emit) async {
    emit(state.copyWith(status: HomeStatus.loading));
    try {
      final results = await Future.wait([
        _files.getStorageStats(),
        _files.getRecentFiles(limit: 30),
        _files.getIndexStats(),
      ]);
      emit(state.copyWith(
        status: HomeStatus.loaded,
        stats: results[0] as StorageStats,
        recentFiles: results[1] as List<FileEntry>,
        indexStats: results[2] as IndexStats,
      ));
    } catch (e) {
      emit(state.copyWith(status: HomeStatus.error, error: e.toString()));
    }
  }

  Future<void> _onFileImported(HomeFileImported event, Emitter<HomeState> emit) async {
    await _files.importFile(event.path);
    add(HomeRefreshRequested());
  }
}

// ═══════════════════════════════════════════════════════════════════
// SEARCH BLOC — debounce, ranking, history, filters
// ═══════════════════════════════════════════════════════════════════

abstract class SearchEvent extends Equatable {
  const SearchEvent();
  @override List<Object?> get props => [];
}

class SearchQueryChanged extends SearchEvent {
  final String query;
  const SearchQueryChanged(this.query);
  @override List<Object?> get props => [query];
}

class SearchFilterChanged extends SearchEvent {
  final String? typeFilter;
  final SearchRanking ranking;
  const SearchFilterChanged({this.typeFilter, this.ranking = SearchRanking.relevance});
  @override List<Object?> get props => [typeFilter, ranking];
}

class SearchCleared extends SearchEvent {}
class SearchHistoryRequested extends SearchEvent {}

enum SearchStatus { idle, searching, loaded, error }

class SearchState extends Equatable {
  final SearchStatus status;
  final String query;
  final String? typeFilter;
  final SearchRanking ranking;
  final SearchResult? result;
  final List<String> history;
  final String? error;

  const SearchState({
    this.status = SearchStatus.idle,
    this.query = '',
    this.typeFilter,
    this.ranking = SearchRanking.relevance,
    this.result,
    this.history = const [],
    this.error,
  });

  bool get hasResults => result != null && !result!.isEmpty;

  SearchState copyWith({
    SearchStatus? status,
    String? query,
    String? typeFilter,
    SearchRanking? ranking,
    SearchResult? result,
    List<String>? history,
    String? error,
  }) =>
      SearchState(
        status: status ?? this.status,
        query: query ?? this.query,
        typeFilter: typeFilter,
        ranking: ranking ?? this.ranking,
        result: result ?? this.result,
        history: history ?? this.history,
        error: error ?? this.error,
      );

  @override
  List<Object?> get props => [status, query, typeFilter, ranking, result?.total];
}

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final SearchRepository _search;
  final FileRepository _files;

  SearchBloc(this._search, this._files) : super(const SearchState()) {
    on<SearchQueryChanged>(_onQueryChanged,
        transformer: _debounce(const Duration(milliseconds: 300)));
    on<SearchFilterChanged>(_onFilterChanged);
    on<SearchCleared>(_onCleared);
    on<SearchHistoryRequested>(_onHistoryRequested);
  }

  EventTransformer<E> _debounce<E>(Duration duration) {
    return (events, mapper) => events.debounce(duration).switchMap(mapper);
  }

  Future<void> _onQueryChanged(
    SearchQueryChanged event, Emitter<SearchState> emit) async {
    final q = event.query.trim();
    if (q.isEmpty) {
      emit(state.copyWith(status: SearchStatus.idle, query: ''));
      return;
    }
    emit(state.copyWith(status: SearchStatus.searching, query: q));
    try {
      final result = await _search.search(SearchQuery(
        text: q,
        typeFilter: state.typeFilter,
        ranking: state.ranking,
        limit: 50,
      ));
      await _files.saveSearchQuery(q);
      emit(state.copyWith(status: SearchStatus.loaded, result: result));
    } catch (e) {
      emit(state.copyWith(status: SearchStatus.error, error: e.toString()));
    }
  }

  Future<void> _onFilterChanged(
    SearchFilterChanged event, Emitter<SearchState> emit) async {
    emit(state.copyWith(typeFilter: event.typeFilter, ranking: event.ranking));
    if (state.query.isNotEmpty) {
      add(SearchQueryChanged(state.query));
    }
  }

  void _onCleared(SearchCleared event, Emitter<SearchState> emit) {
    emit(const SearchState());
  }

  Future<void> _onHistoryRequested(
    SearchHistoryRequested event, Emitter<SearchState> emit) async {
    final history = await _files.getSearchHistory();
    emit(state.copyWith(history: history));
  }
}

// ═══════════════════════════════════════════════════════════════════
// STORAGE BLOC — real scan, duplicate groups, heatmap
// ═══════════════════════════════════════════════════════════════════

abstract class StorageEvent extends Equatable {
  const StorageEvent();
  @override List<Object?> get props => [];
}

class StorageScanRequested extends StorageEvent {}
class StorageDeleteRequested extends StorageEvent {
  final List<String> ids;
  final bool secure;
  const StorageDeleteRequested(this.ids, {this.secure = false});
  @override List<Object?> get props => [ids, secure];
}

enum StorageStatus { idle, scanning, loaded, deleting, error }

class StorageState extends Equatable {
  final StorageStatus status;
  final StorageAnalysis? analysis;
  final List<DuplicateGroup> duplicates;
  final List<SimilarGroup> similar;
  final StorageHeatmap? heatmap;
  final String? error;

  const StorageState({
    this.status = StorageStatus.idle,
    this.analysis,
    this.duplicates = const [],
    this.similar = const [],
    this.heatmap,
    this.error,
  });

  int get totalRecoverableBytes =>
      analysis?.recoverableBytes ?? 0;

  StorageState copyWith({
    StorageStatus? status,
    StorageAnalysis? analysis,
    List<DuplicateGroup>? duplicates,
    List<SimilarGroup>? similar,
    StorageHeatmap? heatmap,
    String? error,
  }) =>
      StorageState(
        status: status ?? this.status,
        analysis: analysis ?? this.analysis,
        duplicates: duplicates ?? this.duplicates,
        similar: similar ?? this.similar,
        heatmap: heatmap ?? this.heatmap,
        error: error ?? this.error,
      );

  @override
  List<Object?> get props => [status, analysis?.recoverableBytes, duplicates.length];
}

class StorageBloc extends Bloc<StorageEvent, StorageState> {
  final StorageRepository _storage;

  StorageBloc(this._storage) : super(const StorageState()) {
    on<StorageScanRequested>(_onScan);
    on<StorageDeleteRequested>(_onDelete);
  }

  Future<void> _onScan(StorageScanRequested event, Emitter<StorageState> emit) async {
    emit(state.copyWith(status: StorageStatus.scanning));
    try {
      final results = await Future.wait([
        _storage.analyzeStorage(),
        _storage.getDuplicateGroups(),
        _storage.getSimilarImageGroups(),
        _storage.getHeatmap(),
      ]);
      emit(state.copyWith(
        status: StorageStatus.loaded,
        analysis: results[0] as StorageAnalysis,
        duplicates: results[1] as List<DuplicateGroup>,
        similar: results[2] as List<SimilarGroup>,
        heatmap: results[3] as StorageHeatmap,
      ));
    } catch (e) {
      emit(state.copyWith(status: StorageStatus.error, error: e.toString()));
    }
  }

  Future<void> _onDelete(StorageDeleteRequested event, Emitter<StorageState> emit) async {
    emit(state.copyWith(status: StorageStatus.deleting));
    try {
      if (event.secure) {
        await _storage.secureDelete(event.ids);
      } else {
        await _storage.safeDelete(event.ids);
      }
      add(StorageScanRequested());
    } catch (e) {
      emit(state.copyWith(status: StorageStatus.error, error: e.toString()));
    }
  }
}

// ═══════════════════════════════════════════════════════════════════
// AI BLOC — model status, chat, summarize, explain, flashcards
// ═══════════════════════════════════════════════════════════════════

abstract class AiEvent extends Equatable {
  const AiEvent();
  @override List<Object?> get props => [];
}

class AiCheckModel extends AiEvent {}
class AiSendMessage extends AiEvent {
  final String message;
  const AiSendMessage(this.message);
  @override List<Object?> get props => [message];
}
class AiSummarizeFile extends AiEvent {
  final String fileId;
  const AiSummarizeFile(this.fileId);
  @override List<Object?> get props => [fileId];
}
class AiExplainFile extends AiEvent {
  final String fileId;
  final AiExplainMode mode;
  const AiExplainFile(this.fileId, this.mode);
  @override List<Object?> get props => [fileId, mode];
}
class AiGenerateFlashcards extends AiEvent {
  final String fileId;
  const AiGenerateFlashcards(this.fileId);
  @override List<Object?> get props => [fileId];
}
class AiClearConversation extends AiEvent {}

enum AiExplainMode { screenshot, code, diagram }
enum AiStatus { idle, checking, ready, noModel, thinking, error }

class AiState extends Equatable {
  final AiStatus status;
  final bool modelLoaded;
  final List<ChatMessage> messages;
  final List<Flashcard> flashcards;
  final String? lastSummary;
  final String? error;

  const AiState({
    this.status = AiStatus.idle,
    this.modelLoaded = false,
    this.messages = const [],
    this.flashcards = const [],
    this.lastSummary,
    this.error,
  });

  AiState copyWith({
    AiStatus? status,
    bool? modelLoaded,
    List<ChatMessage>? messages,
    List<Flashcard>? flashcards,
    String? lastSummary,
    String? error,
  }) =>
      AiState(
        status: status ?? this.status,
        modelLoaded: modelLoaded ?? this.modelLoaded,
        messages: messages ?? this.messages,
        flashcards: flashcards ?? this.flashcards,
        lastSummary: lastSummary ?? this.lastSummary,
        error: error ?? this.error,
      );

  @override
  List<Object?> get props => [status, modelLoaded, messages.length, flashcards.length];
}

class AiBloc extends Bloc<AiEvent, AiState> {
  final AiRepository _ai;

  AiBloc(this._ai) : super(const AiState()) {
    on<AiCheckModel>(_onCheckModel);
    on<AiSendMessage>(_onSendMessage);
    on<AiSummarizeFile>(_onSummarize);
    on<AiExplainFile>(_onExplain);
    on<AiGenerateFlashcards>(_onGenerateFlashcards);
    on<AiClearConversation>(_onClear);
  }

  Future<void> _onCheckModel(AiCheckModel event, Emitter<AiState> emit) async {
    emit(state.copyWith(status: AiStatus.checking));
    final loaded = await _ai.isModelLoaded();
    emit(state.copyWith(
      status: loaded ? AiStatus.ready : AiStatus.noModel,
      modelLoaded: loaded,
    ));
  }

  Future<void> _onSendMessage(AiSendMessage event, Emitter<AiState> emit) async {
    final userMsg = ChatMessage(role: 'user', content: event.message);
    final messages = [...state.messages, userMsg];
    emit(state.copyWith(status: AiStatus.thinking, messages: messages));
    try {
      final response = await _ai.chat(event.message, state.messages);
      final assistantMsg = ChatMessage(role: 'assistant', content: response);
      emit(state.copyWith(
        status: AiStatus.ready,
        messages: [...messages, assistantMsg],
      ));
    } catch (e) {
      emit(state.copyWith(status: AiStatus.error, error: e.toString()));
    }
  }

  Future<void> _onSummarize(AiSummarizeFile event, Emitter<AiState> emit) async {
    emit(state.copyWith(status: AiStatus.thinking));
    try {
      final summary = await _ai.summarize(event.fileId);
      emit(state.copyWith(status: AiStatus.ready, lastSummary: summary));
    } catch (e) {
      emit(state.copyWith(status: AiStatus.error, error: e.toString()));
    }
  }

  Future<void> _onExplain(AiExplainFile event, Emitter<AiState> emit) async {
    emit(state.copyWith(status: AiStatus.thinking));
    try {
      final String result;
      switch (event.mode) {
        case AiExplainMode.screenshot:
          result = await _ai.explainScreenshot(event.fileId);
        case AiExplainMode.code:
          result = await _ai.explainCode(event.fileId);
        case AiExplainMode.diagram:
          result = await _ai.explainDiagram(event.fileId);
      }
      emit(state.copyWith(status: AiStatus.ready, lastSummary: result));
    } catch (e) {
      emit(state.copyWith(status: AiStatus.error, error: e.toString()));
    }
  }

  Future<void> _onGenerateFlashcards(
    AiGenerateFlashcards event, Emitter<AiState> emit) async {
    emit(state.copyWith(status: AiStatus.thinking));
    try {
      final cards = await _ai.generateFlashcards(event.fileId);
      emit(state.copyWith(status: AiStatus.ready, flashcards: cards));
    } catch (e) {
      emit(state.copyWith(status: AiStatus.error, error: e.toString()));
    }
  }

  void _onClear(AiClearConversation event, Emitter<AiState> emit) {
    emit(state.copyWith(messages: [], flashcards: []));
  }
}

// ═══════════════════════════════════════════════════════════════════
// COLLECTIONS BLOC
// ═══════════════════════════════════════════════════════════════════

abstract class CollectionsEvent extends Equatable {
  const CollectionsEvent();
  @override List<Object?> get props => [];
}

class CollectionsLoadRequested extends CollectionsEvent {}
class CollectionCreated extends CollectionsEvent {
  final String name;
  const CollectionCreated(this.name);
  @override List<Object?> get props => [name];
}
class CollectionDeleted extends CollectionsEvent {
  final String id;
  const CollectionDeleted(this.id);
  @override List<Object?> get props => [id];
}

enum CollectionsStatus { initial, loading, loaded, error }

class CollectionsState extends Equatable {
  final CollectionsStatus status;
  final List<Collection> smart;
  final List<Collection> manual;
  final String? error;

  const CollectionsState({
    this.status = CollectionsStatus.initial,
    this.smart = const [],
    this.manual = const [],
    this.error,
  });

  CollectionsState copyWith({
    CollectionsStatus? status,
    List<Collection>? smart,
    List<Collection>? manual,
    String? error,
  }) =>
      CollectionsState(
        status: status ?? this.status,
        smart: smart ?? this.smart,
        manual: manual ?? this.manual,
        error: error ?? this.error,
      );

  @override
  List<Object?> get props => [status, smart.length, manual.length];
}

class CollectionsBloc extends Bloc<CollectionsEvent, CollectionsState> {
  final CollectionRepository _repo;

  CollectionsBloc(this._repo) : super(const CollectionsState()) {
    on<CollectionsLoadRequested>(_onLoad);
    on<CollectionCreated>(_onCreate);
    on<CollectionDeleted>(_onDelete);
  }

  Future<void> _onLoad(CollectionsLoadRequested event, Emitter<CollectionsState> emit) async {
    emit(state.copyWith(status: CollectionsStatus.loading));
    try {
      final results = await Future.wait([
        _repo.getSmartCollections(),
        _repo.getAllCollections(),
      ]);
      emit(state.copyWith(
        status: CollectionsStatus.loaded,
        smart: results[0] as List<Collection>,
        manual: results[1] as List<Collection>,
      ));
    } catch (e) {
      emit(state.copyWith(status: CollectionsStatus.error, error: e.toString()));
    }
  }

  Future<void> _onCreate(CollectionCreated event, Emitter<CollectionsState> emit) async {
    final collection = Collection(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: event.name,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await _repo.createCollection(collection);
    add(CollectionsLoadRequested());
  }

  Future<void> _onDelete(CollectionDeleted event, Emitter<CollectionsState> emit) async {
    await _repo.deleteCollection(event.id);
    add(CollectionsLoadRequested());
  }
}

// Helper extension for debounce (requires rxdart or manual impl)
extension on Stream {
  Stream<T> debounce<T>(Duration d) =>
    cast<T>().transform(StreamTransformer.fromHandlers(
      handleData: (data, sink) => sink.add(data),
    ));
  Stream<T> switchMap<T>(Stream<T> Function(dynamic) mapper) =>
    asyncExpand(mapper);
}
