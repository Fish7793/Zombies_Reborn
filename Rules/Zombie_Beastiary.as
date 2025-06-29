//TODO (check other todos throughout this file too)
//  make page size and main menu size the same (get rid of stretch ratio on main page?)
//  add X button to close page or main menu
//  add a back button on pages to go back to main menu
//  add a hotkey or button that opens the main menu
//  make the GUI cover the map gui
//  change page type to the same page type of main menu

#include "EasyUI.as"
#define CLIENT_ONLY

EasyUI@ ui;
//todo put this stuff in a namespace
MenuItem@[] beastiaryMenuItems;

class Page : StandardPane
{
    Page(EasyUI@ ui, string titleText, string descriptionText, string texture, Vec2f frameDim=Vec2f(32.0, 32.0), uint frameIndex=0)
    {
        super(ui);
        Label@ title = StandardLabel();
        title.SetText(titleText);
        title.SetMargin(0, 10);
        title.SetAlignment(0.5f, 0.0f);

        Label@ description = StandardLabel();
        description.SetText(descriptionText);
        description.SetMargin(10, 10);

        Vec2f iconDim(128.0, 128.0);
        Icon@ icon = StandardIcon();
        icon.SetTexture(texture);
        icon.SetMinSize(iconDim.x, iconDim.y);
        icon.SetMaxSize(iconDim.x, iconDim.y);
        icon.SetStretchRatio(1.0, 1.0);
        icon.SetFrameDim(frameDim.x, frameDim.y);
        icon.SetFrameIndex(frameIndex);
        icon.SetFixedAspectRatio(false);
        icon.SetMargin(10, 10);

        List@ descriptionIcon = StandardList();
        descriptionIcon.AddComponent(description);
        descriptionIcon.AddComponent(icon);
        descriptionIcon.SetCellWrap(2);

        this.AddComponent(title);
        this.AddComponent(descriptionIcon);
        this.SetAlignment(0.5f, 0.5f);
        this.SetPadding(50, 50);
        this.SetVisible(false);
    }
}

class MenuButtonReleaseHandler : EventHandler
{
    List@ menuContainer;
    Page@ page;

    MenuButtonReleaseHandler(List@ otherMenuContainer, Page@ otherPage)
    {
        @menuContainer = otherMenuContainer;
        @page = otherPage;
    }

    void Handle()
    {
        //TODO:
        //set main page invisible, open the new page
        
        if (menuContainer !is null)
        {
            menuContainer.SetVisible(false);
        }

        // if (page !is null)
        // {
        page.SetVisible(true);
        // }
        // if (cast<Page>(page) is null)
        // {
        //     print("NULL PAGE");
        // }
        // else {
        //     print("NOT NULL PAGE");
        // }
    }
}

class MenuItem : StandardPane
{
    //todo remove these as members if not needed, maybe handle AddEventListener outside the class
    Page@ page;
    Button@ button;

    MenuItem(EasyUI@ ui, List@ menuContainer, Page@ otherPage, Button@ otherButton)
    {
        super(ui);
        @page = @otherPage;
        @button = @otherButton;
        button.AddEventListener(Event::Release, MenuButtonReleaseHandler(menuContainer, otherPage));
    }

    void SetType(StandardPaneType type)
    {
        this.type = type;
    }
}

void addBeastiaryMenuItem(EasyUI@ ui, List@ menuContainer, Pane@ menu, string texture, Vec2f frameDim=Vec2f(32.0, 32.0), uint frameIndex=0)
{
    // TODO: fix text
    Page@ page = Page(ui, texture, texture, texture);
    ui.AddComponent(page);

    Vec2f menuItemDim(128.0, 128.0);

    Icon@ menuIcon = StandardIcon();
    menuIcon.SetTexture(texture);
    menuIcon.SetMinSize(menuItemDim.x, menuItemDim.y);
    menuIcon.SetMaxSize(menuItemDim.x, menuItemDim.y);
    menuIcon.SetStretchRatio(1.0, 1.0);
    menuIcon.SetFrameDim(frameDim.x, frameDim.y);
    menuIcon.SetFrameIndex(frameIndex);
    menuIcon.SetFixedAspectRatio(false);

    Button@ menuButton = StandardButton(ui);
    menuButton.AddComponent(menuIcon);

    MenuItem@ menuItem = MenuItem(ui, menuContainer, page, menuButton);
    menuItem.SetMinSize(menuItemDim.x, menuItemDim.y);
    menuItem.SetMaxSize(menuItemDim.x, menuItemDim.y);
    menuItem.SetMargin(10, 10);
    menuItem.AddComponent(menuButton);
    
    beastiaryMenuItems.push_back(menuItem);

    menu.AddComponent(menuItem);
}

List@ createBeastiaryMainPage(EasyUI@ ui)
{
    //make scrollable
    Label@ label = StandardLabel();
    label.SetText("Beastiary");
    label.SetColor(color_black);
    label.SetAlignment(0.5f, 0.0f);

    List@ title = StandardList();
    title.SetAlignment(0.5f, 0.0f);
    // title.SetStretchRatio(1.0f, 1.0f);
    title.AddComponent(label);
    // title.SetMargin(0, 10);

    Pane@ menu = StandardPane(ui, StandardPaneType::Window);
    menu.SetAlignment(0.5f, 0.0f);
    menu.SetMaxSize(512, 512);
    // menu.SetStretchRatio(1.0f, 1.0f);
    menu.SetCellWrap(4);
    menu.SetPadding(50, 50);
    // menu.SetMargin(0, 10);

    List@ menuContainer = StandardList();
    menuContainer.SetStretchRatio(1.0f, 1.0f);
    menuContainer.SetAlignment(0.5f, 0.5f);
    menuContainer.SetPadding(0, 100);
    menuContainer.AddComponent(title);
    menuContainer.AddComponent(menu);
    
    // ui.AddComponent(label);
    // ui.AddComponent(menu);
    ui.AddComponent(menuContainer);
    return menuContainer;
}

void onInit(CRules@ this)
{
    onRestart(this);
}

void onRestart(CRules@ this)
{
    @ui = EasyUI();
    List@ menuContainer = createBeastiaryMainPage(ui);
    Pane@ menu = cast<Pane>(menuContainer.getComponents()[1]);

    addBeastiaryMenuItem(ui, menuContainer, menu, "Zombies/Greg/Greg.png");
    addBeastiaryMenuItem(ui, menuContainer, menu, "Zombies/Horror/Horror.png");
    addBeastiaryMenuItem(ui, menuContainer, menu, "Zombies/Skelepede/Skelepede.png", Vec2f(25.0, 25.0));
    addBeastiaryMenuItem(ui, menuContainer, menu, "Zombies/Skeleton/Skeleton.png", Vec2f(25.0, 25.0));
    addBeastiaryMenuItem(ui, menuContainer, menu, "Zombies/Wraith/Wraith.png");
    addBeastiaryMenuItem(ui, menuContainer, menu, "Zombies/Zombie/Zombie.png", Vec2f(25.0, 25.0));
    addBeastiaryMenuItem(ui, menuContainer, menu, "Zombies/ZombieKnight/ZombieKnight.png");
}

void onTick(CRules@ this)
{
    ui.Update();
}

void onRender(CRules@ this)
{
    ui.Render();
    ui.Debug(getControls().isKeyPressed(KEY_LSHIFT));
}