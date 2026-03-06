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
            Expanded(child: _loading ? _buildShimmer() : _buildGrid()),
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

  Widget _buildGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.15,
      ),
      itemCount: _filtered.length,
      itemBuilder: (_, i) => _CompanyCard(
        company: _filtered[i],
        onTap: () => context.go(
          '/${AppConstants.routeInterviewHub}/${AppConstants.routeCodingPrep}/${AppConstants.routeCompanyQuestions}',
          extra: {'companyId': _filtered[i]['id'], 'companyName': _filtered[i]['name']},
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.15,
      ),
      itemCount: 12,
      itemBuilder: (_, __) => Container(
        decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

class _CompanyCard extends StatelessWidget {
  final Map<String, dynamic> company;
  final VoidCallback onTap;
  const _CompanyCard({required this.company, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final easy   = (company['easy'] ?? 0) as int;
    final medium = (company['medium'] ?? 0) as int;
    final hard   = (company['hard'] ?? 0) as int;
    final total  = (company['questions'] ?? 1) as int;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(gradient: AppColors.purpleGradient, borderRadius: BorderRadius.circular(12)),
              child: Center(
                child: Text(
                  company['name'].toString()[0],
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(company['name'].toString(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
            Text('$total questions', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            const Spacer(),
            // Difficulty bar
            Row(children: [
              _DiffBar(flex: easy,   color: AppColors.success),
              const SizedBox(width: 2),
              _DiffBar(flex: medium, color: AppColors.warning),
              const SizedBox(width: 2),
              _DiffBar(flex: hard,   color: AppColors.error),
            ]),
            const SizedBox(height: 4),
            Row(children: [
              _dot(AppColors.success, 'E'),
              const SizedBox(width: 6),
              _dot(AppColors.warning, 'M'),
              const SizedBox(width: 6),
              _dot(AppColors.error, 'H'),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _DiffBar({required int flex, required Color color}) {
    return Expanded(
      flex: flex + 1,
      child: Container(height: 4, decoration: BoxDecoration(color: color.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(2))),
    );
  }

  Widget _dot(Color color, String label) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 3),
      Text(label, style: TextStyle(fontSize: 9, color: color)),
    ]);
  }
}
