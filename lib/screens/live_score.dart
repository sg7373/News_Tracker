import 'dart:async';
import 'package:flutter/material.dart';
import '../models/match.dart';
import '../services/sports_service.dart';

class LiveScoreScreen extends StatefulWidget {
  const LiveScoreScreen({super.key});

  @override
  State<LiveScoreScreen> createState() => _LiveScoreScreenState();
}

class _LiveScoreScreenState extends State<LiveScoreScreen> {
  final SportsService _sportsService = SportsService();

  List<MatchScore> _footballMatches = [];
  List<MatchScore> _cricketMatches = [];
  bool _isLoading = true;
  String? _error;
  bool _isMockMode = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchScores();
    // Auto-refresh scores every 10 seconds for closer to real-time updates
    _timer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted && !_isLoading) {
        _fetchScores(isBackgroundRefresh: true);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchScores({bool isBackgroundRefresh = false}) async {
    if (!isBackgroundRefresh) {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _error = null;
          _isMockMode = false;
        });
      }
    }

    try {
      // Use separate try-catches for each fetch to allow partial success
      List<MatchScore> football = [];
      List<MatchScore> cricket = [];
      String? footballError;
      String? cricketError;

      try {
        football = await _sportsService.fetchFootballMatches();
      } catch (e) {
        footballError = e.toString();
        print("Football fetch failed: $e");
      }

      try {
        cricket = await _sportsService.fetchCricketMatches();
      } catch (e) {
        cricketError = e.toString();
        print("Cricket fetch failed: $e");
      }

      if (mounted) {
        setState(() {
          // Sorting: Live matches first
          football.sort((a, b) => (b.isLive ? 1 : 0).compareTo(a.isLive ? 1 : 0));
          cricket.sort((a, b) => (b.isLive ? 1 : 0).compareTo(a.isLive ? 1 : 0));

          _footballMatches = football;
          _cricketMatches = cricket;
          _isLoading = false;

          // If both failed, show error. If only one failed, we just show what we have.
          if (footballError != null && cricketError != null) {
            final errorStr = (footballError + cricketError).toLowerCase();
            if (errorStr.contains('429') || errorStr.contains('rate') || errorStr.contains('limit')) {
              _isMockMode = true;
              _footballMatches = _sportsService.getMockFootballMatches();
              _cricketMatches = _sportsService.getMockCricketMatches();
              _error = "Free API Limit Exceeded. Showing Mock Data.";
            } else {
              _error = "Failed to load matches. Check connection.";
            }
          } else if (footballError != null || cricketError != null) {
             // Partial error - maybe show a small snackbar or just ignore if we have some data
             // For now, don't set _error so the UI shows the successful part
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (!isBackgroundRefresh) _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _footballMatches.isEmpty && _cricketMatches.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: Colors.red));
    }

    if (_error != null && !_isMockMode && _footballMatches.isEmpty && _cricketMatches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            Text('Failed to load scores', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _fetchScores,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final bool noData = _footballMatches.isEmpty && _cricketMatches.isEmpty;

    if (noData && !_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.sports_soccer, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No live matches right now',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _fetchScores,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchScores,
      color: Colors.red,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 0),
        children: [
          if (_isMockMode)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: Colors.orange.shade50,
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 20, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error ?? 'API Limit Reached. Showing Mock Data.',
                      style: TextStyle(color: Colors.orange.shade900, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          if (_cricketMatches.isNotEmpty) ...[
            _sectionHeader('🏏 Cricket Match Center'),
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _cricketMatches.length,
                itemBuilder: (context, index) {
                  return _matchCard(_cricketMatches[index]);
                },
              ),
            ),
            const SizedBox(height: 24),
          ],
          if (_footballMatches.isNotEmpty) ...[
            _sectionHeader('⚽ Football Match Center'),
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _footballMatches.length,
                itemBuilder: (context, index) {
                  return _matchCard(_footballMatches[index]);
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12, top: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Color _getBadgeColor(String matchType) {
    matchType = matchType.toUpperCase();
    if (matchType.contains('ODI')) return Colors.blue.shade700;
    if (matchType.contains('FC') || matchType.contains('TEST')) return Colors.red.shade600;
    return Colors.grey.shade800; // T20I, etc.
  }

  Widget _matchCard(MatchScore match) {
    final title = (match.venue.isNotEmpty && match.venue != match.sport) ? match.venue : (match.matchType.isNotEmpty ? match.matchType : match.sport);
    final badgeColor = _getBadgeColor(match.matchType);
    final statusColor = match.isLive ? Colors.red.shade700 : Colors.blue.shade700;

    return Container(
      width: 310,
      margin: const EdgeInsets.only(right: 12, bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                if (match.matchType.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: badgeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: badgeColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      match.matchType,
                      style: TextStyle(
                        color: badgeColor,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Teams and Scores
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _teamRow(
                  match.teamA, 
                  match.sport == 'football' ? match.score.split(' - ').first : (match.score.contains('vs') ? match.score.split(' vs ').first : match.score),
                  match.teamALogo,
                ),
                const SizedBox(height: 12),
                _teamRow(
                  match.teamB, 
                  match.sport == 'football' ? match.score.split(' - ').last : (match.score.contains('vs') ? match.score.split(' vs ').last : '-'),
                  match.teamBLogo,
                ),
              ],
            ),
          ),
          
          const Spacer(),

          // Status line
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  if (match.isLive) _PulseDot(),
                  Expanded(
                    child: Text(
                      match.isLive ? 'LIVE · ${match.status}' : (match.date.isNotEmpty ? '${match.date} · ${match.status}' : match.status),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _teamRow(String name, String score, String logoUrl) {
    if (score == '-' || score == name) score = ''; 

    return Row(
      children: [
        // Team Logo
        Container(
          width: 32,
          height: 32,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: logoUrl.isNotEmpty 
            ? ClipOval(child: Image.network(logoUrl, errorBuilder: (_, __, ___) => const Icon(Icons.shield, size: 16, color: Colors.grey)))
            : const Icon(Icons.shield, size: 16, color: Colors.grey),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(width: 8),
        if (score.isNotEmpty)
          Text(
            score,
            maxLines: 1,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: Colors.black,
            ),
          ),
      ],
    );
  }
}

class _PulseDot extends StatefulWidget {
  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat(reverse: true);
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: _controller, curve: Curves.easeIn),
      child: Container(
        width: 6,
        height: 6,
        margin: const EdgeInsets.only(right: 8),
        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
      ),
    );
  }
}
