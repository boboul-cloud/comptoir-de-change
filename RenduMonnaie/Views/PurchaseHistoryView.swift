//
//  PurchaseHistoryView.swift
//  Comptoir de change
//
//  Journal des achats et des ventes enregistrés, et bilan financier de fin de
//  voyage — les deux types de transaction sont comptabilisés et affichés séparément.
//

import SwiftUI

struct PurchaseHistoryView: View {
    let journal: PurchaseJournal
    let rateStore: RateStore
    let locationService: LocationService

    @Environment(\.dismiss) private var dismiss
    @State private var filter: TransactionKind
    @State private var confirmingClear = false
    @State private var selectedEntry: PurchaseEntry?
    @State private var isPreparingReport = false
    @State private var reportURL: URL?
    @State private var showReportShareSheet = false
    /// Devise dans laquelle le total du bilan est exprimé — l'euro par défaut, mais
    /// librement modifiable (utile pour un voyage dont la devise de référence n'est
    /// pas l'euro).
    @AppStorage("deviseBilan") private var deviseBilan = "EUR"

    init(
        journal: PurchaseJournal, rateStore: RateStore, locationService: LocationService,
        initialFilter: TransactionKind = .achat
    ) {
        self.journal = journal
        self.rateStore = rateStore
        self.locationService = locationService
        _filter = State(initialValue: initialFilter)
    }

    private var filteredEntries: [PurchaseEntry] { journal.entries.filter { $0.kind == filter } }
    private var summary: JournalSummary { filteredEntries.summary }

    private var groupedEntries: [(day: Date, entries: [PurchaseEntry])] {
        let calendar = Calendar.autoupdatingCurrent
        let groups = Dictionary(grouping: filteredEntries) { calendar.startOfDay(for: $0.date) }
        return groups.keys.sorted(by: >).map { day in
            (day, groups[day]!.sorted { $0.date > $1.date })
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if journal.entries.isEmpty {
                        emptyState
                    } else {
                        kindFilterPicker
                        if filteredEntries.isEmpty {
                            emptyState
                        } else {
                            summaryCard
                            ForEach(groupedEntries, id: \.day) { group in
                                dayGroup(group)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
                .frame(maxWidth: 520)
                .frame(maxWidth: .infinity)
            }
            .background(Color.paperBG.ignoresSafeArea())
            .navigationTitle(filter.historyTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") { dismiss() }
                }
                if !journal.entries.isEmpty {
                    ToolbarItem(placement: .primaryAction) {
                        if isPreparingReport {
                            ProgressView()
                        } else {
                            Menu {
                                Button {
                                    Task { await prepareReport() }
                                } label: {
                                    Label("Exporter le bilan en PDF", systemImage: "square.and.arrow.up")
                                }
                                .disabled(filteredEntries.isEmpty)
                                Button(role: .destructive) {
                                    confirmingClear = true
                                } label: {
                                    Label("Nouveau voyage", systemImage: "trash")
                                }
                            } label: {
                                Image(systemName: "ellipsis.circle")
                            }
                            .accessibilityLabel("Options du journal")
                        }
                    }
                }
            }
            .confirmationDialog(
                "Effacer l'historique ?",
                isPresented: $confirmingClear,
                titleVisibility: .visible
            ) {
                Button("Supprimer", role: .destructive) { journal.clear() }
                Button("Annuler", role: .cancel) {}
            } message: {
                Text("Cette action supprimera définitivement tous les achats et ventes enregistrés de ce voyage. Elle est irréversible.")
            }
            .sheet(item: $selectedEntry) { entry in
                PurchaseDetailView(entry: entry)
            }
            .sheet(isPresented: $showReportShareSheet) {
                if let reportURL {
                    ActivityView(activityItems: [reportURL])
                }
            }
        }
    }

    // MARK: - Filtre

    private var kindFilterPicker: some View {
        Picker("Type de transaction", selection: $filter) {
            ForEach(TransactionKind.allCases) { kind in
                Text(kind.label).tag(kind)
            }
        }
        .pickerStyle(.segmented)
    }

    // MARK: - Bilan

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(filter.summaryTitle)
                .scaledFont(11, weight: .bold, design: .monospaced)
                .tracking(2.5)
                .foregroundStyle(.white.opacity(0.55))

            Text(countLabel)
                .scaledFont(12, design: .monospaced)
                .foregroundStyle(.white.opacity(0.75))

            VStack(alignment: .leading, spacing: 2) {
                totalCurrencyPicker
                Text(totalAmountText)
                    .scaledFont(34, weight: .bold, design: .monospaced)
                    .foregroundStyle(Color.cream)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
            }
            .padding(.vertical, 2)

            Divider().overlay(.white.opacity(0.12))

            VStack(spacing: 12) {
                ForEach(summary.totals) { totalRow($0) }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.boardBG, in: .rect(cornerRadius: 14))
    }

    private var countLabel: String { filter.countRegistered(summary.count) }

    /// En-tête « TOTAL EN {devise} » : aussi le déclencheur du sélecteur de devise.
    private var totalCurrencyPicker: some View {
        Menu {
            Picker("Devise du bilan", selection: $deviseBilan) {
                ForEach(CurrencyCatalog.all) { c in
                    Text(c.label).tag(c.code)
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(totalHeaderLabel)
                    .scaledFont(10, weight: .semibold, design: .monospaced)
                    .tracking(2)
                Image(systemName: "chevron.up.chevron.down")
                    .scaledFont(8, weight: .bold)
            }
            .foregroundStyle(Color.accentGold)
        }
        .accessibilityLabel(Text("Devise du bilan") + Text(" : ") + Text(LocalizedStringKey(CurrencyCatalog.currency(deviseBilan).country)))
    }

    private var totalHeaderLabel: LocalizedStringKey { "TOTAL EN \(deviseBilan)" }

    private var totalAmountText: String {
        "≈ " + Fmt.amount(totalInDeviseBilan, currency: CurrencyCatalog.currency(deviseBilan)) + " " + deviseBilan
    }

    /// Somme, dans la devise choisie pour le bilan, des transactions affichées (achats
    /// ou ventes, selon le filtre courant), toutes devises confondues.
    private var totalInDeviseBilan: Double {
        summary.totals.reduce(0) { partial, total in
            let rate = total.code == deviseBilan ? 1 : rateStore.rate(from: total.code, to: deviseBilan)
            guard rate > 0 else { return partial }
            return partial + (total.totalPrice + total.totalTip) * rate
        }
    }

    private func totalRow(_ total: JournalSummary.CurrencyTotal) -> some View {
        let currency = CurrencyCatalog.currency(total.code)
        return VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text("\(currency.flag) \(total.code)")
                    .scaledFont(13, weight: .semibold, design: .monospaced)
                    .foregroundStyle(Color.accentGold)
                Spacer()
                Text("\(Fmt.amount(total.totalPrice + total.totalTip, currency: currency)) \(total.code)")
                    .scaledFont(18, weight: .bold, design: .monospaced)
                    .foregroundStyle(Color.cream)
            }
            Text(detailText(total))
                .scaledFont(11, design: .monospaced)
                .foregroundStyle(.white.opacity(0.5))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func detailText(_ total: JournalSummary.CurrencyTotal) -> String {
        var parts = [filter.count(total.count)]
        if total.totalTip > 0 {
            let currency = CurrencyCatalog.currency(total.code)
            parts.append(String(localized: "dont \(Fmt.amount(total.totalTip, currency: currency)) de pourboire"))
        }
        if let equivalent = equivalentInDeviseBilan(total) {
            parts.append(equivalent)
        }
        return parts.joined(separator: " · ")
    }

    /// Contre-valeur approximative dans la devise du bilan, au cours actuel — un repère
    /// utile quand le voyage mélange plusieurs devises.
    private func equivalentInDeviseBilan(_ total: JournalSummary.CurrencyTotal) -> String? {
        guard total.code != deviseBilan else { return nil }
        let rate = rateStore.rate(from: total.code, to: deviseBilan)
        guard rate > 0 else { return nil }
        let value = (total.totalPrice + total.totalTip) * rate
        return "≈ " + Fmt.amount(value, currency: CurrencyCatalog.currency(deviseBilan)) + " " + deviseBilan
    }

    // MARK: - Journal

    private func dayGroup(_ group: (day: Date, entries: [PurchaseEntry])) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(Fmt.day(group.day))
                .scaledFont(11, weight: .semibold)
                .tracking(0.8)
                .textCase(.uppercase)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                ForEach(Array(group.entries.enumerated()), id: \.element.id) { index, entry in
                    row(entry)
                    if index < group.entries.count - 1 {
                        Divider().overlay(Color.cardLine)
                    }
                }
            }
            .padding(.horizontal, 16)
            .background(Color.cardBG, in: .rect(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.cardLine, lineWidth: 1))
        }
    }

    private func row(_ entry: PurchaseEntry) -> some View {
        let priceCurrency = CurrencyCatalog.currency(entry.priceCurrencyCode)
        let paidCurrency = CurrencyCatalog.currency(entry.paidCurrencyCode)
        let changeCurrency = CurrencyCatalog.currency(entry.changeCurrencyCode)
        return HStack(alignment: .top, spacing: 10) {
            Button {
                selectedEntry = entry
            } label: {
                HStack(alignment: .top, spacing: 10) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 5) {
                            Text(entry.note.isEmpty ? entry.kind.label : entry.note)
                                .scaledFont(14, weight: .semibold)
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                            if entry.hasLocation {
                                Image(systemName: "mappin.circle.fill")
                                    .scaledFont(11)
                                    .foregroundStyle(Color.accentGreen)
                            }
                        }
                        Text("\(Fmt.amount(entry.receivedAmount, currency: paidCurrency)) \(entry.paidCurrencyCode) → \(Fmt.amount(entry.changeAmount, currency: changeCurrency)) \(entry.changeCurrencyCode) rendus")
                            .scaledFont(11, design: .monospaced)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 8)
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(Fmt.amount(entry.totalPrice, currency: priceCurrency)) \(entry.priceCurrencyCode)")
                            .scaledFont(14, weight: .semibold, design: .monospaced)
                        Text(Fmt.clock(entry.date))
                            .scaledFont(11, design: .monospaced)
                            .foregroundStyle(.secondary)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button {
                delete(entry)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .scaledFont(15)
                    .foregroundStyle(.secondary.opacity(0.5))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(entry.kind.deleteLabel)
        }
        .padding(.vertical, 12)
    }

    private func delete(_ entry: PurchaseEntry) {
        guard let index = journal.entries.firstIndex(where: { $0.id == entry.id }) else { return }
        withAnimation { journal.remove(at: IndexSet(integer: index)) }
    }

    // MARK: - État vide

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: journal.entries.isEmpty ? "bag" : filter.icon)
                .scaledFont(34)
                .foregroundStyle(Color.accentGreen)
            Text(filter.emptyStateTitle)
                .scaledFont(17, weight: .semibold)
            Text(filter.emptyStateMessage)
                .scaledFont(13)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .padding(.top, 80)
    }

    // MARK: - Partage

    /// Reconstitue le lieu de chaque transaction affichée (géocodage inverse quand une
    /// position a été relevée), puis met en page et exporte le bilan détaillé en PDF
    /// avant de proposer le partage système.
    private func prepareReport() async {
        isPreparingReport = true
        defer { isPreparingReport = false }

        var rows: [PurchaseReportView.Row] = []
        for entry in filteredEntries.sorted(by: { $0.date < $1.date }) {
            var placeName: String?
            if let latitude = entry.latitude, let longitude = entry.longitude {
                placeName = await locationService.placeName(latitude: latitude, longitude: longitude)
            }
            rows.append(.init(entry: entry, placeName: placeName))
        }

        let report = PurchaseReportView(
            kind: filter,
            rows: rows,
            summary: summary,
            totalCurrencyCode: deviseBilan,
            total: totalInDeviseBilan,
            generatedAt: Date()
        )

        if let url = PDFExporter.export(report, fileName: "Bilan-\(filter.rawValue)s.pdf") {
            reportURL = url
            showReportShareSheet = true
        }
    }
}

#Preview {
    let journal = PurchaseJournal(defaults: UserDefaults(suiteName: "preview-history")!)
    journal.add(PurchaseEntry(
        note: "Café",
        priceCurrencyCode: "EUR", price: 4.5,
        paidCurrencyCode: "USD", receivedAmount: 10,
        changeAmount: 5.06, changeCurrencyCode: "EUR",
        rate: 0.9
    ))
    return PurchaseHistoryView(journal: journal, rateStore: RateStore(), locationService: LocationService())
}
