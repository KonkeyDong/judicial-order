package defs

import "core:testing"

@(test)
test_name_file :: proc(test: ^testing.T) {
	Case :: struct {
		raw:  string,
		want: string,
	}
	cases := [?]Case {
		{"", ""},
		{"Hale", "hale"},
		{"LawStudent", "law_student"},
		{"LawProfessor", "law_professor"},
		{"SupremeCourtJustice", "supreme_court_justice"},
		{"Unarmed", "unarmed"},
		{"Down", "down"},
		{"BattleFieldDeath", "battle_field_death"},
	}
	for c in cases {
		testing.expect_value(test, name_file(c.raw), c.want)
	}

	testing.expect_value(test, name_file(name_base(.LawStudent)), "law_student")
}

@(test)
test_spaced_camel :: proc(test: ^testing.T) {
	Case :: struct {
		raw:  string,
		want: string,
	}
	cases := [?]Case {
		{"", ""},
		{"A", "A"},
		{"Spear", "Spear"},
		{"aB", "a B"},
		{"LawStudent", "Law Student"},
		{"DeanOfLaw", "Dean Of Law"},
		{"SupremeCourtGavel", "Supreme Court Gavel"},
		{"FoisGras", "Fois Gras"},
		{"HTML", "H T M L"},
		{"Blaze1", "Blaze1"},
		{"Already Spaced", "Already  Spaced"},
	}
	for c in cases {
		testing.expect_value(test, spaced_camel(c.raw), c.want)
	}
}

@(test)
test_item_name_display :: proc(test: ^testing.T) {
	Case :: struct {
		name: Item_Name,
		want: string,
	}
	cases := [?]Case {
		{.NoItem, "NoItem"},
		{.Unarmed, "Unarmed"},
		{.SmallBriefcase, "Small Briefcase"},
		{.MediumBriefcase, "Medium Briefcase"},
		{.LargeBriefcase, "Large Briefcase"},
		{.SteelBriefcase, "Steel Briefcase"},
		{.BroadBriefcase, "Broad Briefcase"},
		{.AttacheBriefcase, "Attache Briefcase"},
		{.LaptopBriefcase, "Laptop Briefcase"},
		{.BriefcaseOfHonor, "Briefcase Of Honor"},
		{.BriefcaseOfJustice, "Briefcase Of Justice"},
		{.LawBreaker, "Law Breaker"},
		{.Gavel, "Gavel"},
		{.OakGavel, "Oak Gavel"},
		{.EbonyGavel, "Ebony Gavel"},
		{.HouseGavel, "House Gavel"},
		{.SenateGavel, "Senate Gavel"},
		{.SupremeCourtGavel, "Supreme Court Gavel"},
		{.Pencil, "Pencil"},
		{.GelPen, "Gel Pen"},
		{.BallpointPen, "Ballpoint Pen"},
		{.FountainPen, "Fountain Pen"},
		{.CalligraphyPen, "Calligraphy Pen"},
		{.Subpoena, "Subpoena"},
		{.SummonsNotice, "Summons Notice"},
		{.EvictionNotice, "Eviction Notice"},
		{.SearchWarrant, "Search Warrant"},
		{.DeathWarrant, "Death Warrant"},
		{.Spear, "Spear"},
		{.PowerSpear, "Power Spear"},
		{.BronzeScales, "Bronze Scales"},
		{.SteelScales, "Steel Scales"},
		{.ChromeScales, "Chrome Scales"},
		{.MassScales, "Mass Scales"},
		{.UnbalancedScales, "Unbalanced Scales"},
		{.ScalesOfHonor, "Scales Of Honor"},
		{.Hotdog, "Hotdog"},
		{.FoisGras, "Fois Gras"},
		{.Caviar, "Caviar"},
		{.Antidote, "Antidote"},
		{.StrategicWithdrawal, "Strategic Withdrawal"},
		{.BreadOfLife, "Bread Of Life"},
		{.PowerPotion, "Power Potion"},
		{.DefensePotion, "Defense Potion"},
		{.LegsOfHaste, "Legs Of Haste"},
		{.TurboPepper, "Turbo Pepper"},
		{.OrbOfLight, "Orb Of Light"},
		{.DomingoEgg, "Domingo Egg"},
		{.MoonStone, "Moon Stone"},
		{.LunarDew, "Lunar Dew"},
		{.SugoiMizugi, "Sugoi Mizugi"},
		{.KituiHuku, "Kitui Huku"},
	}
	for c in cases {
		testing.expect_value(test, item_name_display(c.name), c.want)
	}
}

@(test)
test_name_display_and_base :: proc(test: ^testing.T) {
	Case :: struct {
		name:    Name,
		display: string,
		base:    string,
	}
	cases := [?]Case {
		{.Hale, "Hale", "Hale"},
		{.Dale, "Dale", "Dale"},
		{.Judy, "Judy", "Judy"},
		{.Trudy, "Trudy", "Trudy"},
		{.Anthony, "Anthony", "Anthony"},
		{.Bellweather, "Bellweather", "Bellweather"},
		{.Olivia, "Olivia", "Olivia"},
		{.Lexi, "Lexi", "Lexi"},
		{.Fanix, "Fanix", "Fanix"},
		{.Sirena, "Sirena", "Sirena"},
		{.LawStudent, "Law Student", "LawStudent"},
		{.LawProfessor, "Law Professor", "LawProfessor"},
		{.DeanOfLaw, "Dean of Law", "DeanOfLaw"},
		{.Bailiff, "Bailiff", "Bailiff"},
		{.Sheriff, "Sheriff", "Sheriff"},
		{.SupremeCourtJustice, "Supreme Court Justice", "SupremeCourtJustice"},
		{.CircuitJudge, "Circuit Judge", "CircuitJudge"},
		{.DistrictJudge, "District Judge", "DistrictJudge"},
		{.MagistrateJudge, "Magistrate Judge", "MagistrateJudge"},
		{.BankruptcyJudge, "Bankruptcy Judge", "BankruptcyJudge"},
		{.AppellateJudge, "Appellate Judge", "AppellateJudge"},
		{.Clerk, "Clerk", "Clerk"},
		{.CourtReporter, "Court Reporter", "CourtReporter"},
		{.Stenographers, "Stenographers", "Stenographers"},
		{.ProbationOfficer, "Probation Officer", "ProbationOfficer"},
		{.Interpreter, "Interpreter", "Interpreter"},
		{.LawLibrarian, "Law Librarian", "LawLibrarian"},
		{.LegalSecretary, "Legal Secretary", "LegalSecretary"},
		{.JuryConsultant, "Jury Consultant", "JuryConsultant"},
		{.DistrictAttorney, "District Attorney", "DistrictAttorney"},
		{.CountyCommissioner, "County Commissioner", "CountyCommissioner"},
		{.Prosecutor, "Prosecutor", "Prosecutor"},
		{.Defense, "Defense", "Defense"},
		{.CorporateAttorney, "Corporate Attorney", "CorporateAttorney"},
		{.FamilyLawAttorney, "Family Law Attorney", "FamilyLawAttorney"},
		{.PatentAttorney, "Patent Attorney", "PatentAttorney"},
		{.ImmigrationAttorney, "Immigration Attorney", "ImmigrationAttorney"},
		{.PublicDefenseAttorney, "Public Defense Attorney", "PublicDefenseAttorney"},
		{.JudgeAdvocateGeneral, "Judge Advocate General", "JudgeAdvocateGeneral"},
	}
	for c in cases {
		testing.expect_value(test, name_display(c.name), c.display)
		testing.expect_value(test, name_base(c.name), c.base)
	}
}

@(test)
test_name_display_unknown :: proc(test: ^testing.T) {
	unknown := cast(Name)999
	old_logger := context.logger
	context.logger = {}
	display := name_display(unknown)
	context.logger = old_logger

	testing.expect_value(test, display, "Unknown")
	testing.expect_value(test, name_base(unknown), "")
}
