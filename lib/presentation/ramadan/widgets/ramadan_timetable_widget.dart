// part of '../events.dart';

// /// إمساكية رمضان - جدول أوقات الفجر والمغرب
// /// Ramadan timetable - Fajr and Maghrib times
// class RamadanTimetableWidget extends StatelessWidget {
//   const RamadanTimetableWidget({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final isDark = context.theme.brightness == Brightness.dark;

//     return GetBuilder<RamadanController>(
//       init: RamadanController.instance,
//       builder: (ctrl) {
//         return Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // رأس الجدول
//             Container(
//               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   colors: isDark
//                       ? [
//                           Colors.blue.shade900,
//                           Colors.indigo.shade900,
//                         ]
//                       : [
//                           Colors.blue.shade500,
//                           Colors.indigo.shade600,
//                         ],
//                 ),
//                 borderRadius: const BorderRadius.vertical(
//                   top: Radius.circular(12),
//                 ),
//               ),
//               child: Row(
//                 children: [
//                   Expanded(
//                     flex: 1,
//                     child: Text(
//                       'day'.tr,
//                       style: context.textTheme.bodySmall?.copyWith(
//                         fontWeight: FontWeight.bold,
//                         color: Colors.white,
//                       ),
//                       textAlign: TextAlign.center,
//                     ),
//                   ),
//                   Expanded(
//                     flex: 2,
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Icon(
//                           SolarIconsBold.moon,
//                           size: 14,
//                           color: Colors.blue.shade200,
//                         ),
//                         const Gap(4),
//                         Text(
//                           'Fajr'.tr,
//                           style: context.textTheme.bodySmall?.copyWith(
//                             fontWeight: FontWeight.bold,
//                             color: Colors.white,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   Expanded(
//                     flex: 2,
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Icon(
//                           SolarIconsBold.sun,
//                           size: 14,
//                           color: Colors.orange.shade300,
//                         ),
//                         const Gap(4),
//                         Text(
//                           'Maghrib'.tr,
//                           style: context.textTheme.bodySmall?.copyWith(
//                             fontWeight: FontWeight.bold,
//                             color: Colors.white,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),

//             // صفوف الجدول
//             Container(
//               decoration: BoxDecoration(
//                 color: isDark ? Colors.grey.shade900 : Colors.white,
//                 borderRadius: const BorderRadius.vertical(
//                   bottom: Radius.circular(12),
//                 ),
//                 border: Border.all(
//                   color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
//                 ),
//               ),
//               child: ListView.separated(
//                 shrinkWrap: true,
//                 physics: const NeverScrollableScrollPhysics(),
//                 itemCount: ctrl.ramadanDaysCount,
//                 separatorBuilder: (_, __) => Divider(
//                   height: 1,
//                   color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
//                 ),
//                 itemBuilder: (context, index) {
//                   final day = index + 1;
//                   final isToday =
//                       ctrl.hijriNow.hMonth == 9 && ctrl.hijriNow.hDay == day;
//                   final timetable = ctrl.getRamadanTimetable();
//                   final dayData =
//                       timetable.isNotEmpty && index < timetable.length
//                           ? timetable[index]
//                           : {'fajr': '--:--', 'maghrib': '--:--'};

//                   return Container(
//                     padding: const EdgeInsets.symmetric(
//                         horizontal: 12, vertical: 12),
//                     decoration: BoxDecoration(
//                       gradient: isToday
//                           ? LinearGradient(
//                               colors: isDark
//                                   ? [
//                                       Colors.blue.shade900.withOpacity(0.4),
//                                       Colors.indigo.shade900.withOpacity(0.3),
//                                     ]
//                                   : [
//                                       Colors.blue.shade50,
//                                       Colors.indigo.shade50,
//                                     ],
//                             )
//                           : null,
//                       color: !isToday
//                           ? (index.isOdd
//                               ? (isDark
//                                   ? Colors.grey.shade800.withOpacity(0.3)
//                                   : Colors.grey.shade50)
//                               : null)
//                           : null,
//                     ),
//                     child: Row(
//                       children: [
//                         // رقم اليوم
//                         Expanded(
//                           flex: 1,
//                           child: Container(
//                             padding: const EdgeInsets.symmetric(
//                               horizontal: 8,
//                               vertical: 4,
//                             ),
//                             decoration: isToday
//                                 ? BoxDecoration(
//                                     color: Colors.blue.shade500,
//                                     borderRadius: BorderRadius.circular(8),
//                                   )
//                                 : null,
//                             child: Row(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               mainAxisSize: MainAxisSize.min,
//                               children: [
//                                 Text(
//                                   '$day'.convertNumbers(),
//                                   style: context.textTheme.bodyMedium?.copyWith(
//                                     fontWeight: FontWeight.bold,
//                                     color: isToday
//                                         ? Colors.white
//                                         : (isDark
//                                             ? Colors.grey.shade300
//                                             : Colors.grey.shade700),
//                                   ),
//                                 ),
//                                 if (isToday) ...[
//                                   const Gap(2),
//                                   const Icon(
//                                     SolarIconsBold.star,
//                                     size: 10,
//                                     color: Colors.amber,
//                                   ),
//                                 ],
//                               ],
//                             ),
//                           ),
//                         ),

//                         // وقت الفجر
//                         Expanded(
//                           flex: 2,
//                           child: Container(
//                             padding: const EdgeInsets.symmetric(
//                               horizontal: 8,
//                               vertical: 6,
//                             ),
//                             margin: const EdgeInsets.symmetric(horizontal: 4),
//                             decoration: BoxDecoration(
//                               color: isToday
//                                   ? Colors.indigo
//                                       .withOpacity(isDark ? 0.3 : 0.1)
//                                   : (isDark
//                                       ? Colors.grey.shade800.withOpacity(0.5)
//                                       : Colors.grey.shade100),
//                               borderRadius: BorderRadius.circular(8),
//                             ),
//                             child: Text(
//                               '${dayData['fajr']}'.convertNumbers(),
//                               style: context.textTheme.bodyMedium?.copyWith(
//                                 fontWeight:
//                                     isToday ? FontWeight.bold : FontWeight.w500,
//                                 color: isToday ? Colors.indigo.shade400 : null,
//                               ),
//                               textAlign: TextAlign.center,
//                             ),
//                           ),
//                         ),

//                         // وقت المغرب
//                         Expanded(
//                           flex: 2,
//                           child: Container(
//                             padding: const EdgeInsets.symmetric(
//                               horizontal: 8,
//                               vertical: 6,
//                             ),
//                             margin: const EdgeInsets.symmetric(horizontal: 4),
//                             decoration: BoxDecoration(
//                               color: isToday
//                                   ? Colors.orange
//                                       .withOpacity(isDark ? 0.3 : 0.1)
//                                   : (isDark
//                                       ? Colors.grey.shade800.withOpacity(0.5)
//                                       : Colors.grey.shade100),
//                               borderRadius: BorderRadius.circular(8),
//                             ),
//                             child: Text(
//                               '${dayData['maghrib']}'.convertNumbers(),
//                               style: context.textTheme.bodyMedium?.copyWith(
//                                 fontWeight:
//                                     isToday ? FontWeight.bold : FontWeight.w500,
//                                 color: isToday ? Colors.orange.shade600 : null,
//                               ),
//                               textAlign: TextAlign.center,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ],
//         );
//       },
//     );
//   }
// }
