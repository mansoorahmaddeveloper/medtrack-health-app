import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';

import 'package:intl/intl.dart';



import '../../core/constants/app_constants.dart';

import '../../core/constants/routes.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_theme.dart';

import '../../core/widgets/app_components.dart';

import '../../core/widgets/app_header.dart';

import '../../core/widgets/app_toast.dart';

import '../../data/repositories/profile_repository.dart';

import '../../data/repositories/vitals_repository.dart';



class ProfileScreen extends ConsumerStatefulWidget {

  const ProfileScreen({super.key});



  @override

  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();

}



class _ProfileScreenState extends ConsumerState<ProfileScreen> {

  final _name = TextEditingController();

  final _weight = TextEditingController();

  final _contactName = TextEditingController();

  final _contactPhone = TextEditingController();

  final _contactRelationship = TextEditingController();

  DateTime? _dob;

  String? _bloodType;

  String? _primaryContactId;

  bool _loaded = false;



  @override

  void dispose() {

    _name.dispose();

    _weight.dispose();

    _contactName.dispose();

    _contactPhone.dispose();

    _contactRelationship.dispose();

    super.dispose();

  }



  Future<void> _load() async {

    final profileRepo = ref.read(profileRepositoryProvider);

    final vitalsRepo = ref.read(vitalsRepositoryProvider);

    final profile = await profileRepo.getProfile();

    final contacts = await profileRepo.watchEmergencyContacts().first;

    final weightVitals = await vitalsRepo

        .watchVitals(patientId: AppConstants.defaultProfileId, type: 'weight')

        .first;



    if (!mounted) return;

    _name.text = profile?.name ?? '';

    _dob = profile?.dateOfBirth;

    _bloodType = profile?.bloodType;

    if (weightVitals.isNotEmpty) {

      _weight.text = weightVitals.first.valuePrimary.toStringAsFixed(0);

    }

    if (contacts.isNotEmpty) {

      final c = contacts.first;

      _primaryContactId = c.id;

      _contactName.text = c.name;

      _contactPhone.text = c.phone;

      _contactRelationship.text = c.relationship ?? '';

    }

    setState(() => _loaded = true);

  }



  @override

  void initState() {

    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) => _load());

  }



  Future<void> _save() async {

    if (_name.text.trim().isEmpty) {

      AppToast.error(context, 'Full name is required');

      return;

    }

    final profileRepo = ref.read(profileRepositoryProvider);

    final vitalsRepo = ref.read(vitalsRepositoryProvider);

    final allergies = decodeJsonList((await profileRepo.getProfile())?.allergiesJson ?? '[]');



    await profileRepo.upsertProfile(

      name: _name.text.trim(),

      dateOfBirth: _dob,

      bloodType: _bloodType,

      allergies: allergies,

    );



    final weight = double.tryParse(_weight.text.trim());

    if (weight != null && weight > 0) {

      await vitalsRepo.logVital(

        patientId: AppConstants.defaultProfileId,

        type: 'weight',

        valuePrimary: weight,

        unit: 'kg',

        loggedByProfileId: AppConstants.defaultProfileId,

      );

    }



    if (_contactName.text.trim().isNotEmpty && _contactPhone.text.trim().isNotEmpty) {

      if (_primaryContactId != null) {

        await profileRepo.deleteEmergencyContact(_primaryContactId!);

      }

      await profileRepo.addEmergencyContact(

        name: _contactName.text.trim(),

        phone: _contactPhone.text.trim(),

        relationship: _contactRelationship.text.trim().isEmpty

            ? null

            : _contactRelationship.text.trim(),

      );

      _primaryContactId = null;

    }



    if (!mounted) return;

    AppToast.success(context, 'Profile saved successfully');

    await _load();

  }



  @override

  Widget build(BuildContext context) {

    if (!_loaded) {

      return const Scaffold(

        backgroundColor: AppColors.background,

        body: Center(child: CircularProgressIndicator()),

      );

    }



    return Scaffold(

      backgroundColor: AppColors.background,

      body: SafeArea(

        child: Column(

          children: [

            const AppHeader(),

            Expanded(

              child: ListView(

                padding: const EdgeInsets.fromLTRB(

                  AppSpacing.containerPadding,

                  AppSpacing.stackGap,

                  AppSpacing.containerPadding,

                  120,

                ),

                children: [

                  Text('Profile Settings', style: AppTypography.headlineLgMobile),

                  const SizedBox(height: 4),

                  Text(

                    'Manage your personal details and app preferences.',

                    style: AppTypography.bodyMd,

                  ),

                  const SizedBox(height: AppSpacing.sectionGap),

                  _SectionCard(

                    title: 'Personal Details',

                    icon: Icons.person_outline,

                    children: [

                      AppTextField(controller: _name, label: 'Full Name'),

                      const SizedBox(height: AppSpacing.stackGap),

                      AppCard(

                        onTap: () async {

                          final picked = await showDatePicker(

                            context: context,

                            initialDate: _dob ?? DateTime(1975, 8, 14),

                            firstDate: DateTime(1900),

                            lastDate: DateTime.now(),

                          );

                          if (picked != null) setState(() => _dob = picked);

                        },

                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),

                        child: Row(

                          children: [

                            Expanded(

                              child: Column(

                                crossAxisAlignment: CrossAxisAlignment.start,

                                children: [

                                  Text('Date of Birth', style: AppTypography.labelSm),

                                  const SizedBox(height: 4),

                                  Text(

                                    _dob == null

                                        ? 'Select date'

                                        : DateFormat('MM/dd/yyyy').format(_dob!),

                                    style: AppTypography.bodyMd,

                                  ),

                                ],

                              ),

                            ),

                            const Icon(Icons.calendar_today_outlined, color: AppColors.outline),

                          ],

                        ),

                      ),

                      const SizedBox(height: AppSpacing.stackGap),

                      DropdownButtonFormField<String>(

                        initialValue: _bloodType,

                        decoration: const InputDecoration(labelText: 'Blood Type'),

                        items: const ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-']

                            .map((b) => DropdownMenuItem(value: b, child: Text(b)))

                            .toList(),

                        onChanged: (v) => setState(() => _bloodType = v),

                      ),

                      const SizedBox(height: AppSpacing.stackGap),

                      AppTextField(

                        controller: _weight,

                        label: 'Weight (kg)',

                        keyboardType: TextInputType.number,

                      ),

                    ],

                  ),

                  const SizedBox(height: AppSpacing.sectionGap),

                  _SectionCard(

                    title: 'Emergency Contact',

                    icon: Icons.contact_emergency_outlined,

                    iconColor: AppColors.error,

                    children: [

                      AppTextField(controller: _contactName, label: 'Contact Name'),

                      const SizedBox(height: AppSpacing.stackGap),

                      AppTextField(

                        controller: _contactPhone,

                        label: 'Phone Number',

                        keyboardType: TextInputType.phone,

                      ),

                      const SizedBox(height: AppSpacing.stackGap),

                      AppTextField(controller: _contactRelationship, label: 'Relationship'),

                    ],

                  ),

                  const SizedBox(height: AppSpacing.sectionGap),

                  AppPrimaryButton(label: 'Save Profile', onPressed: _save),

                  const SizedBox(height: AppSpacing.sectionGap),

                  const SectionHeader(title: 'More tools', usePrimaryColor: false),

                  const SizedBox(height: AppSpacing.stackGap),

                  ..._toolLinks(context),

                ],

              ),

            ),

          ],

        ),

      ),

    );

  }



  List<Widget> _toolLinks(BuildContext context) {

    final items = [

      (Icons.insights_outlined, 'Vitals & trends', AppRoutes.vitals),

      (Icons.ios_share, 'Share records', AppRoutes.export),

      (Icons.picture_as_pdf_outlined, 'Emergency ID', AppRoutes.emergencyId),

      (Icons.contact_emergency_outlined, 'All emergency contacts', AppRoutes.emergencyContacts),

      (Icons.cloud_sync_outlined, 'Account & sync', AppRoutes.login),

    ];

    return items

        .map(

          (item) => Padding(

            padding: const EdgeInsets.only(bottom: AppSpacing.stackGap),

            child: AppCard(

              onTap: () => context.push(item.$3),

              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),

              child: ListTile(

                contentPadding: EdgeInsets.zero,

                leading: Icon(item.$1, color: AppColors.primary),

                title: Text(item.$2, style: AppTypography.labelLg),

                trailing: const Icon(Icons.chevron_right, color: AppColors.outline),

              ),

            ),

          ),

        )

        .toList();

  }

}



class _SectionCard extends StatelessWidget {

  const _SectionCard({

    required this.title,

    required this.icon,

    required this.children,

    this.iconColor,

  });



  final String title;

  final IconData icon;

  final List<Widget> children;

  final Color? iconColor;



  @override

  Widget build(BuildContext context) {

    return AppCard(

      padding: const EdgeInsets.all(AppSpacing.gutter),

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          Row(

            children: [

              Text(title, style: AppTypography.labelLg.copyWith(fontWeight: FontWeight.w700)),

              const Spacer(),

              Icon(icon, color: iconColor ?? AppColors.outline.withValues(alpha: 0.5), size: 28),

            ],

          ),

          const SizedBox(height: AppSpacing.gutter),

          ...children,

        ],

      ),

    );

  }

}



class EditProfileScreen extends ConsumerStatefulWidget {

  const EditProfileScreen({super.key});



  @override

  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();

}



class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {

  final _name = TextEditingController();

  final _allergy = TextEditingController();

  DateTime? _dob;

  String? _bloodType;

  final _allergies = <String>[];



  @override

  void dispose() {

    _name.dispose();

    _allergy.dispose();

    super.dispose();

  }



  Future<void> _load() async {

    final profile = await ref.read(profileRepositoryProvider).getProfile();

    if (profile == null || !mounted) return;

    _name.text = profile.name;

    _dob = profile.dateOfBirth;

    _bloodType = profile.bloodType;

    _allergies

      ..clear()

      ..addAll(decodeJsonList(profile.allergiesJson));

    setState(() {});

  }



  @override

  void initState() {

    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) => _load());

  }



  @override

  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: AppColors.background,

      appBar: AppBar(title: const Text('Edit profile')),

      body: ListView(

        padding: const EdgeInsets.all(AppSpacing.containerPadding),

        children: [

          AppTextField(controller: _name, label: 'Full name *'),

          const SizedBox(height: AppSpacing.stackGap),

          AppCard(

            onTap: () async {

              final picked = await showDatePicker(

                context: context,

                initialDate: _dob ?? DateTime(1990),

                firstDate: DateTime(1900),

                lastDate: DateTime.now(),

              );

              if (picked != null) setState(() => _dob = picked);

            },

            child: ListTile(

              contentPadding: EdgeInsets.zero,

              title: Text('Date of birth', style: AppTypography.labelLg),

              subtitle: Text(

                _dob == null ? 'Select' : DateFormat.yMMMd().format(_dob!),

                style: AppTypography.bodyMd,

              ),

            ),

          ),

          const SizedBox(height: AppSpacing.stackGap),

          DropdownButtonFormField<String>(

            initialValue: _bloodType,

            decoration: const InputDecoration(labelText: 'Blood type'),

            items: const ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-']

                .map((b) => DropdownMenuItem(value: b, child: Text(b)))

                .toList(),

            onChanged: (v) => setState(() => _bloodType = v),

          ),

          const SizedBox(height: AppSpacing.stackGap),

          AppTextField(

            controller: _allergy,

            label: 'Add allergy',

          ),

          Align(

            alignment: Alignment.centerRight,

            child: TextButton.icon(

              onPressed: () {

                final text = _allergy.text.trim();

                if (text.isEmpty) return;

                setState(() {

                  _allergies.add(text);

                  _allergy.clear();

                });

              },

              icon: const Icon(Icons.add),

              label: const Text('Add'),

            ),

          ),

          Wrap(

            spacing: 8,

            children: _allergies

                .map(

                  (a) => AppFilterChip(

                    label: a,

                    selected: true,

                    onTap: () => setState(() => _allergies.remove(a)),

                  ),

                )

                .toList(),

          ),

          const SizedBox(height: AppSpacing.sectionGap),

          AppPrimaryButton(

            label: 'Save profile',

            onPressed: () async {

              if (_name.text.trim().isEmpty) {

                AppToast.error(context, 'Name is required');

                return;

              }

              await ref.read(profileRepositoryProvider).upsertProfile(

                    name: _name.text.trim(),

                    dateOfBirth: _dob,

                    bloodType: _bloodType,

                    allergies: _allergies,

                  );

              if (context.mounted) context.pop();

            },

          ),

        ],

      ),

    );

  }

}



class EmergencyContactsScreen extends ConsumerWidget {

  const EmergencyContactsScreen({super.key});



  @override

  Widget build(BuildContext context, WidgetRef ref) {

    final repo = ref.watch(profileRepositoryProvider);

    return Scaffold(

      backgroundColor: AppColors.background,

      appBar: AppBar(title: const Text('Emergency contacts')),

      floatingActionButton: FloatingActionButton(

        onPressed: () => _showAddDialog(context, ref),

        child: const Icon(Icons.add),

      ),

      body: StreamBuilder(

        stream: repo.watchEmergencyContacts(),

        builder: (context, snapshot) {

          final contacts = snapshot.data ?? [];

          if (contacts.isEmpty) {

            return const EmptyState(

              message: 'No emergency contacts yet.',

              icon: Icons.contact_emergency_outlined,

            );

          }

          return ListView.separated(

            padding: const EdgeInsets.all(AppSpacing.containerPadding),

            itemCount: contacts.length,

            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.stackGap),

            itemBuilder: (context, i) {

              final c = contacts[i];

              return AppCard(

                child: Row(

                  children: [

                    Expanded(

                      child: Column(

                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [

                          Text(c.name, style: AppTypography.labelLg),

                          Text(

                            '${c.phone}${c.relationship != null ? ' · ${c.relationship}' : ''}',

                            style: AppTypography.labelSm,

                          ),

                        ],

                      ),

                    ),

                    IconButton(

                      icon: const Icon(Icons.delete_outline, color: AppColors.error),

                      onPressed: () => repo.deleteEmergencyContact(c.id),

                    ),

                  ],

                ),

              );

            },

          );

        },

      ),

    );

  }



  Future<void> _showAddDialog(BuildContext context, WidgetRef ref) async {

    final name = TextEditingController();

    final phone = TextEditingController();

    final relationship = TextEditingController();

    await showDialog<void>(

      context: context,

      builder: (ctx) => AlertDialog(

        title: Text('Add contact', style: AppTypography.headlineLgMobile),

        content: Column(

          mainAxisSize: MainAxisSize.min,

          children: [

            AppTextField(controller: name, label: 'Name'),

            const SizedBox(height: 12),

            AppTextField(controller: phone, label: 'Phone'),

            const SizedBox(height: 12),

            AppTextField(controller: relationship, label: 'Relationship'),

          ],

        ),

        actions: [

          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),

          FilledButton(

            onPressed: () async {

              if (name.text.trim().isEmpty || phone.text.trim().isEmpty) return;

              await ref.read(profileRepositoryProvider).addEmergencyContact(

                    name: name.text.trim(),

                    phone: phone.text.trim(),

                    relationship: relationship.text.trim().isEmpty ? null : relationship.text.trim(),

                  );

              if (ctx.mounted) Navigator.pop(ctx);

            },

            child: const Text('Save'),

          ),

        ],

      ),

    );

  }

}


