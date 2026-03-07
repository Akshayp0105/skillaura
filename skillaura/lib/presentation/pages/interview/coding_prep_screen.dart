import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../services/coding_service.dart';

class CodingPrepScreen extends StatefulWidget {
  const CodingPrepScreen({super.key});

  @override
  State<CodingPrepScreen> createState() => _CodingPrepScreenState();
}

class _CodingPrepScreenState extends State<CodingPrepScreen> {
  final _service = CodingService();
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _companies = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    _searchController.addListener(_filter);
  }

  Future<void> _load() async {
    final data = await _service.getCompanies();
    if (mounted) setState(() { _companies = data; _filtered = data; _loading = false; });
  }

  void _filter() {
    final q = _searchController.text.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? _companies
          : _companies.where((c) => c['name'].toString().toLowerCase().contains(q)).toList();
    });
  }

  @override
  void dispose() { _searchController.dispose(); _service.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            _buildSearch(),
            Expanded(child: _loading ? _buildShimmer() : _buildList()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: AppColors.textPrimary),
            ),
          ),
          const SizedBox(width: 14),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Coding Preparation', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              Text('Select a company to start practicing', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: 'Search companies...',
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textHint),
          suffixText: '${_filtered.length} companies',
          suffixStyle: const TextStyle(color: AppColors.textHint, fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildList() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: _filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final company = _filtered[i];
        final total = (company['questions'] ?? 0) as int;
        final easy = (company['easy'] ?? 0) as int;
        final medium = (company['medium'] ?? 0) as int;
        final hard = (company['hard'] ?? 0) as int;
        final name = company['name'].toString();

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => context.go(
              '/${AppConstants.routeInterviewHub}/${AppConstants.routeCodingPrep}/${AppConstants.routeCompanyQuestions}',
              extra: {'companyId': company['id'], 'companyName': name},
            ),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
              ),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      gradient: AppColors.purpleGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        name[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Name + question count + difficulty bar
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                        const SizedBox(height: 2),
                        Text('$total questions', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        const SizedBox(height: 6),
                        Row(children: [
                          _diffBar(easy, AppColors.success),
                          const SizedBox(width: 2),
                          _diffBar(medium, AppColors.warning),
                          const SizedBox(width: 2),
                          _diffBar(hard, AppColors.error),
                        ]),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textHint),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _diffBar(int flex, Color color) {
    return Expanded(
      flex: flex + 1,
      child: Container(
        height: 4,
        decoration: BoxDecoration(color: color.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(2)),
      ),
    );
  }

  Widget _buildShimmer() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: 10,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, __) => Container(
        height: 76,
        decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
