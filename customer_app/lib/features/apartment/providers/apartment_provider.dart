import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/apartment_model.dart';
import '../../../models/society_ticket_model.dart';
import '../../../repositories/apartment_repository.dart';

class ApartmentState {
  final bool isLoading;
  final ApartmentResidentData? profileData;
  final List<SocietyTicketModel> tickets;
  final SocietyTicketModel? selectedTicket;
  final String? errorMessage;
  final String statusFilter;
  final String categoryFilter;
  final String searchQuery;

  ApartmentState({
    this.isLoading = false,
    this.profileData,
    this.tickets = const [],
    this.selectedTicket,
    this.errorMessage,
    this.statusFilter = 'All',
    this.categoryFilter = 'All',
    this.searchQuery = '',
  });

  ApartmentState copyWith({
    bool? isLoading,
    ApartmentResidentData? profileData,
    List<SocietyTicketModel>? tickets,
    SocietyTicketModel? selectedTicket,
    String? errorMessage,
    String? statusFilter,
    String? categoryFilter,
    String? searchQuery,
  }) {
    return ApartmentState(
      isLoading: isLoading ?? this.isLoading,
      profileData: profileData ?? this.profileData,
      tickets: tickets ?? this.tickets,
      selectedTicket: selectedTicket ?? this.selectedTicket,
      errorMessage: errorMessage,
      statusFilter: statusFilter ?? this.statusFilter,
      categoryFilter: categoryFilter ?? this.categoryFilter,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  List<SocietyTicketModel> get filteredTickets {
    return tickets.where((t) {
      if (statusFilter != 'All' && t.status.toLowerCase() != statusFilter.toLowerCase()) {
        if (statusFilter == 'Active' && !['New', 'Acknowledged', 'Assigned', 'In Progress', 'Reopened'].contains(t.status)) {
          return false;
        } else if (statusFilter != 'Active') {
          return false;
        }
      }
      if (categoryFilter != 'All' && t.category.toLowerCase() != categoryFilter.toLowerCase()) {
        return false;
      }
      if (searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase();
        final matchesSubject = t.subject.toLowerCase().contains(q);
        final matchesId = t.ticketId.toLowerCase().contains(q);
        final matchesFlat = t.flatNumber.toLowerCase().contains(q);
        final matchesDesc = t.description.toLowerCase().contains(q);
        if (!matchesSubject && !matchesId && !matchesFlat && !matchesDesc) return false;
      }
      return true;
    }).toList();
  }
}

class ApartmentNotifier extends StateNotifier<ApartmentState> {
  final ApartmentRepository _repository;

  ApartmentNotifier(this._repository) : super(ApartmentState()) {
    refreshAll();
  }

  Future<void> refreshAll() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final profile = await _repository.getResidentProfile();
      final tickets = await _repository.getTickets();
      state = state.copyWith(
        isLoading: false,
        profileData: profile,
        tickets: tickets,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> loadTickets() async {
    try {
      final tickets = await _repository.getTickets();
      state = state.copyWith(tickets: tickets);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> loadTicketDetails(String id) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final ticket = await _repository.getTicketById(id);
      state = state.copyWith(isLoading: false, selectedTicket: ticket);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void setFilter(String status) {
    state = state.copyWith(statusFilter: status);
  }

  void setCategoryFilter(String category) {
    state = state.copyWith(categoryFilter: category);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  Future<SocietyTicketModel> createComplaint({
    required String subject,
    required String description,
    required String category,
    required String priority,
    List<String>? attachments,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final newTicket = await _repository.createTicket(
        subject: subject,
        description: description,
        category: category,
        priority: priority,
        attachments: attachments,
      );
      state = state.copyWith(
        isLoading: false,
        tickets: [newTicket, ...state.tickets],
      );
      return newTicket;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      rethrow;
    }
  }

  Future<void> sendReply(String ticketId, String text, {List<String>? images}) async {
    try {
      final updated = await _repository.replyToTicket(ticketId, text: text, images: images);
      state = state.copyWith(
        selectedTicket: updated,
        tickets: state.tickets.map((t) => t.id == ticketId ? updated : t).toList(),
      );
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      rethrow;
    }
  }

  Future<void> updateStatus(String ticketId, String status, {String? reason}) async {
    try {
      await _repository.updateTicketStatus(ticketId, status: status, reason: reason);
      await loadTicketDetails(ticketId);
      await loadTickets();
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      rethrow;
    }
  }

  Future<void> addInternalNote(String ticketId, String text) async {
    try {
      await _repository.addInternalNote(ticketId, text: text);
      await loadTicketDetails(ticketId);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      rethrow;
    }
  }

  Future<void> resolveComplaint(String ticketId, String notes, {List<String>? photos}) async {
    try {
      await _repository.resolveTicket(ticketId, resolutionNotes: notes, resolutionPhotos: photos);
      await loadTicketDetails(ticketId);
      await loadTickets();
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      rethrow;
    }
  }

  Future<void> reopenComplaint(String ticketId, String reason) async {
    try {
      await _repository.reopenTicket(ticketId, reason: reason);
      await loadTicketDetails(ticketId);
      await loadTickets();
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      rethrow;
    }
  }
}

final apartmentProvider = StateNotifierProvider<ApartmentNotifier, ApartmentState>((ref) {
  return ApartmentNotifier(ref.watch(apartmentRepositoryProvider));
});
