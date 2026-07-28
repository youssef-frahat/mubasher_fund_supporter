import os
from reportlab.lib.pagesizes import letter, landscape
from reportlab.lib import colors
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, PageBreak, HRFlowable
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.pdfgen import canvas

def create_presentation_pdf(output_filename):
    doc = SimpleDocTemplate(
        output_filename,
        pagesize=landscape(letter),
        rightMargin=36,
        leftMargin=36,
        topMargin=36,
        bottomMargin=36
    )

    styles = getSampleStyleSheet()

    # Colors
    bg_dark = colors.HexColor('#0D1117')
    primary_green = colors.HexColor('#00E676')
    accent_blue = colors.HexColor('#3B82F6')
    card_bg = colors.HexColor('#161B22')
    text_white = colors.HexColor('#FFFFFF')
    text_gray = colors.HexColor('#9CA3AF')

    title_style = ParagraphStyle(
        'DocTitle',
        parent=styles['Heading1'],
        fontName='Helvetica-Bold',
        fontSize=26,
        textColor=primary_green,
        alignment=1, # Center
        spaceAfter=10
    )

    subtitle_style = ParagraphStyle(
        'DocSubtitle',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=14,
        textColor=text_gray,
        alignment=1,
        spaceAfter=20
    )

    h2_style = ParagraphStyle(
        'SectionH2',
        parent=styles['Heading2'],
        fontName='Helvetica-Bold',
        fontSize=18,
        textColor=primary_green,
        spaceAfter=12
    )

    body_style = ParagraphStyle(
        'BodyDark',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=11,
        textColor=text_white,
        leading=16,
        spaceAfter=8
    )

    story = []

    # --- SLIDE 1: COVER ---
    story.append(Spacer(1, 40))
    story.append(Paragraph("WATHEQA (وثيقة)", title_style))
    story.append(Paragraph("The Premier Investment Funds Platform & Portfolio Simulator in Egypt", subtitle_style))
    story.append(Spacer(1, 20))

    cover_table_data = [
        [
            Paragraph("<b>Architecture</b><br/>Flutter Clean Architecture<br/>Supabase PostgreSQL DB", body_style),
            Paragraph("<b>Security & Auth</b><br/>Google OAuth + Email<br/>Biometric Fingerprint Lock", body_style),
            Paragraph("<b>Admin Control</b><br/>Live Web Dashboard<br/>1-Click NAV & YTD Price Editor", body_style),
        ]
    ]
    t_cover = Table(cover_table_data, colWidths=[240, 240, 240])
    t_cover.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), card_bg),
        ('TEXTCOLOR', (0,0), (-1,-1), text_white),
        ('PADDING', (0,0), (-1,-1), 16),
        ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
        ('GRID', (0,0), (-1,-1), 1, colors.HexColor('#30363D')),
    ]))
    story.append(t_cover)
    story.append(PageBreak())

    # --- SLIDE 2: CORE FEATURES SUMMARY ---
    story.append(Paragraph("Core Application Features Overview", h2_style))
    story.append(HRFlowable(width="100%", thickness=2, color=primary_green, spaceAfter=15))

    features_data = [
        ["Feature Area", "Functionality & Technology", "User Benefit"],
        ["1. Authentication", "Google Sign-In, Email Signup, Strict Input Validation, Biometrics", "Instant secure access & verified investor badges"],
        ["2. Market Engine", "Real-time Market Gauge (Gain/Decline/Static) & 200+ EIMA Funds Search", "Live Egyptian fund prices & AI sentiment analysis"],
        ["3. Robo-Advisor", "Risk Assessment Questionnaire, Expected ROI & Automated Portfolio Allocation", "Tailored investment mix in Gold, Stocks & Treasury Bills"],
        ["4. Portfolio Simulator", "Health Score (0-100), User Portfolio Isolation, Asset Holding on Accepted State", "Complete P&L tracking without financial risk"],
        ["5. Top 10 League", "Top 10 Leaders, Bottom 10 Watchlist & AI BUY/EXIT Signals", "Clear market insights & top performing fund ranks"],
        ["6. Admin Dashboard", "Supabase DB sync, Add Investor Modal, Quick NAV Updater & Bilingual UI", "Instant backend administrative management"]
    ]

    t_feat = Table(features_data, colWidths=[140, 380, 200])
    t_feat.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), primary_green),
        ('TEXTCOLOR', (0,0), (-1,0), colors.black),
        ('FONTNAME', (0,0), (-1,0), 'Helvetica-Bold'),
        ('BACKGROUND', (0,1), (-1,-1), card_bg),
        ('TEXTCOLOR', (0,1), (-1,-1), text_white),
        ('GRID', (0,0), (-1,-1), 1, colors.HexColor('#30363D')),
        ('PADDING', (0,0), (-1,-1), 8),
    ]))
    story.append(t_feat)
    story.append(PageBreak())

    # --- SLIDE 3: TECH STACK & ARCHITECTURE ---
    story.append(Paragraph("System Architecture & Technical Stack", h2_style))
    story.append(HRFlowable(width="100%", thickness=2, color=accent_blue, spaceAfter=15))

    tech_data = [
        [
            Paragraph("<b>Mobile App (Flutter)</b><br/>• BLoC State Management<br/>• ScreenUtil Responsiveness<br/>• GoRouter & Deep Links<br/>• Easy Localization (Ar/En)", body_style),
            Paragraph("<b>Backend (Supabase)</b><br/>• PostgreSQL Relational DB<br/>• Supabase Auth & OAuth<br/>• Realtime Subscriptions<br/>• RLS Security Policies", body_style),
            Paragraph("<b>Admin Web Portal</b><br/>• Vanilla CSS Glassmorphism<br/>• Chart.js Analytics<br/>• Supabase JS Client<br/>• Audit Logs Tracking", body_style),
        ]
    ]
    t_tech = Table(tech_data, colWidths=[240, 240, 240])
    t_tech.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), card_bg),
        ('TEXTCOLOR', (0,0), (-1,-1), text_white),
        ('PADDING', (0,0), (-1,-1), 16),
        ('GRID', (0,0), (-1,-1), 1, accent_blue),
    ]))
    story.append(t_tech)

    # Class for Canvas Background
    class NumberedCanvas(canvas.Canvas):
        def __init__(self, *args, **kwargs):
            super().__init__(*args, **kwargs)
            self._saved_page_states = []

        def showPage(self):
            self._saved_page_states.append(dict(self.__dict__))
            self._startPage()

        def save(self):
            num_pages = len(self._saved_page_states)
            for state in self._saved_page_states:
                self.__dict__.update(state)
                self.draw_page_decorations(num_pages)
                super().showPage()
            super().save()

        def draw_page_decorations(self, page_count):
            self.saveState()
            self.setFillColor(bg_dark)
            self.rect(0, 0, 792, 612, fill=True, stroke=False)
            
            # Header line
            self.setStrokeColor(primary_green)
            self.setLineWidth(1)
            self.line(36, 580, 756, 580)
            
            # Footer text
            self.setFont("Helvetica", 9)
            self.setFillColor(text_gray)
            self.drawString(36, 20, "Watheqa (وثيقة) — Master Platform Presentation")
            self.drawRightString(756, 20, f"Page {self._pageNumber} of {page_count}")
            self.restoreState()

    doc.build(story, canvasmaker=NumberedCanvas)
    print(f"PDF Presentation created successfully: {output_filename}")

if __name__ == "__main__":
    out_path = os.path.join(os.getcwd(), "Watheqa_Master_Presentation.pdf")
    create_presentation_pdf(out_path)
